# Story 001 — Allowlist safe read-only filters & generalized worktree-git

## Goal
Auto-approve the largest prompt buckets (pipe-to-filter, per-worktree git) by adding only
provably side-effect-free entries to the committed `.claude/settings.json` allowlist.

## Changes
Add to `permissions.allow` in `.claude/settings.json`:
- Read-only pipe filters: `tail *`, `head *`, `wc *`, `sort *`, `cut *`, `comm *`, `uniq *`,
  `nl *`, `column *`, `jq *`.
- `sleep *` (used to wait for CI checks to register, replacing poll loops).
- `grep -r *` (read-only codebase scan; complements existing `grep -n`/`-rn`/`-rln`).
- Generalized worktree-git wildcards under the stable parent so a new slug never re-prompts:
  `git -C /Users/Private/Documents/Code/ProjectHana-worktrees/* <verb> *` for the safe verbs
  status, add, commit, push, log, diff, show, checkout, switch, merge, fetch, branch,
  check-ignore, rev-parse, ls-files, restore, stash, mv, rm, worktree.

## Acceptance Criteria
- [ ] All listed filters/verbs present in committed `.claude/settings.json` `allow`.
- [ ] No destructive standalone command (`rm -rf`, `git push --force` to arbitrary remotes, etc.)
      is newly auto-approved by these entries.
- [ ] JSON remains valid (parses); `just lint` passes.

## Notes
`tail/head/wc/sort/cut/comm/uniq/nl/column/jq/sleep/grep` have no side effects on their own.
The worktree-git wildcard is bounded to the pre-authorized worktrees parent dir.
