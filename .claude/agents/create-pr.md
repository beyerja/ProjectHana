---
name: create-pr
description: Push the story branch and open a PR against main with a description derived from the story spec
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start create-pr "<story-id>" || true
```

Read `<story-dir>/spec.md` and recent commits. **First integrate the latest `origin/main` into the
story branch BEFORE pushing**, because branch protection requires the PR head to be up to date and
`main` routinely advances mid-run:
```
git -C <worktree> fetch origin main
git -C <worktree> rebase origin/main   # rebase (linear) > merge here: a merge commit that adds no
                                       # build-relevant diff vs base does NOT retrigger pull_request CI,
                                       # leaving the PR BLOCKED with no checks. A rebased head always does.
```
Resolve any conflicts (regenerate `Hanahuac.xcodeproj` rather than hand-merging the pbxproj), then push
(use `git -C <worktree> …` in a worktree run rather than `cd … && git push`):
```
git push -u origin <branch>
```
(If `main` advances again *after* the PR is open and it goes BLOCKED/DIRTY, re-integrate. Force-push is
blocked under Auto mode, so once a branch is already pushed prefer `git merge origin/main` + push; only
when that produces no CI run, nudge it with a single `git commit --allow-empty` + push.)

Create a PR targeting main using `gh`. **Write the body to a file with the Write tool, then pass
`--body-file`** — never a heredoc or `--body "$(…)"` (command substitution / heredocs are always
prompted; see CLAUDE.md → "Emit allowlistable command shapes"). **Write the body file as
`<story-dir>/pr-body.md`, not bare `.workflow/…`** — the story dir is already gitignored, so the
scratch file never lingers as an untracked stray (a prior run left a stray `.workflow/pr-body-002.md`
behind):
```
gh pr create --base main --head <branch> --title "<story title>" --body-file <story-dir>/pr-body.md
```
- Body file contents: goal, bulleted summary of changes, test plan checklist.

Write PR URL and number to `<story-dir>/pr.md`.
Count tool calls (R/W/E/B) and estimate chars, then run (ignore errors):
```
just log end create-pr "<story-id>" <R> <W> <E> <B> <est_chars> "" || true
```
Append to `<story-dir>/log.md`: `<timestamp> create-pr: DONE — <URL>`.

Output STATUS: DONE — PR #<number> at <URL>.
