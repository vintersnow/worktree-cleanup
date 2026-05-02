# worktree-cleanup

Simple helper script for finding and removing Git worktrees whose branches are
already merged into the base branch, or whose upstream branch no longer exists.

By default, the script runs in dry-run mode and only prints what it would do.

## Usage

```sh
./cleanup-worktrees.zsh
```

Remove eligible worktrees:

```sh
./cleanup-worktrees.zsh --delete
```

Remove eligible worktrees and delete their local branches:

```sh
./cleanup-worktrees.zsh --delete --delete-branch
```

## Options

- `--base <branch>`: Base branch to compare against. Defaults to `main`.
- `--remote <name>`: Remote name to fetch and compare against. Defaults to `origin`.
- `--delete`: Actually remove eligible worktrees. Without this, the script is a dry-run.
- `--delete-branch`: Delete the local branch after removing its worktree.
- `--force`: Pass `--force` to `git worktree remove`.

Protected branches such as `main`, `master`, `develop`, `staging`, and
`production` are never removed.
