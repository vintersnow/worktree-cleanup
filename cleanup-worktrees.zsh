#!/usr/bin/env zsh
set -euo pipefail

base=${BASE:-main}
remote=${REMOTE:-origin}
delete=0
delete_branch=0
force=()

protected='^(main|master|develop|dev|staging|production|prod|test|deploy)$'

while [[ $# -gt 0 ]]; do
  case $1 in
    --delete) delete=1 ;;
    --delete-branch) delete_branch=1 ;;
    --force) force=(--force) ;;
    --base) base=$2; shift ;;
    --remote) remote=$2; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

repo_root=$(git rev-parse --show-toplevel)

git fetch "$remote" --prune

base_ref="$remote/$base"
git rev-parse --verify --quiet "$base_ref" >/dev/null ||
  { echo "base ref not found: $base_ref" >&2; exit 1 }

git worktree list --porcelain | while IFS= read -r line; do
  case "$line" in
    worktree\ *)
      worktree_path="${line#worktree }"
      branch_ref=""
      ;;
    branch\ *)
      branch_ref="${line#branch }"
      branch="${branch_ref#refs/heads/}"
      ;;
    "")
      [[ -n "${worktree_path:-}" ]] || continue

      if [[ "$worktree_path" == "$repo_root" ]]; then
        echo "skip main worktree: $worktree_path"
      elif [[ -z "${branch_ref:-}" ]]; then
        echo "skip detached/no branch: $worktree_path"
      elif [[ "$branch" =~ $protected ]]; then
        echo "skip protected: $branch"
      elif [[ ! -d "$worktree_path" ]]; then
        echo "stale metadata: $worktree_path"
        (( delete )) && git worktree prune || echo "  dry-run: git worktree prune"
      elif [[ -n "$(git -C "$worktree_path" status --porcelain)" ]]; then
        echo "skip dirty: $branch"
      else
        upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch")
        reason=""

        if [[ -n "$upstream" ]] && ! git rev-parse --verify --quiet "$upstream" >/dev/null; then
          reason="upstream gone: $upstream"
        elif git merge-base --is-ancestor "$branch" "$base_ref"; then
          reason="merged into: $base_ref"
        fi

        if [[ -n "$reason" ]]; then
          echo "remove: $branch"
          echo "  path: $worktree_path"
          echo "  reason: $reason"

          if (( delete )); then
            git worktree remove "${force[@]}" "$worktree_path"

            if (( delete_branch )) && git show-ref --verify --quiet "refs/heads/$branch"; then
              git branch -d "$branch" || echo "  branch not deleted: $branch"
            fi
          else
            echo "  dry-run: git worktree remove ${force[*]} '$worktree_path'"
            (( delete_branch )) && echo "  dry-run: git branch -d '$branch'"
          fi
        else
          echo "keep: $branch"
        fi
      fi

      worktree_path=""
      branch_ref=""
      branch=""
      ;;
  esac
done

(( delete )) && git worktree prune || echo "dry-run: git worktree prune"
