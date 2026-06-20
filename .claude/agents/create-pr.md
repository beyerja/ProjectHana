---
name: create-pr
description: Push the story branch and open a PR against main with a description derived from the story spec
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start create-pr "<story-id>" || true
```

Read `<story-dir>/spec.md` and recent commits. Push the current branch (use `git -C <worktree> …` in a
worktree run rather than `cd … && git push`):
```
git push -u origin <branch>
```

Create a PR targeting main using `gh`. **Write the body to a file with the Write tool, then pass
`--body-file`** — never a heredoc or `--body "$(…)"` (command substitution / heredocs are always
prompted; see CLAUDE.md → "Emit allowlistable command shapes"):
```
gh pr create --base main --head <branch> --title "<story title>" --body-file <path-to-body-file>
```
- Body file contents: goal, bulleted summary of changes, test plan checklist.

Write PR URL and number to `<story-dir>/pr.md`.
Count tool calls (R/W/E/B) and estimate chars, then run (ignore errors):
```
just log end create-pr "<story-id>" <R> <W> <E> <B> <est_chars> "" || true
```
Append to `<story-dir>/log.md`: `<timestamp> create-pr: DONE — <URL>`.

Output STATUS: DONE — PR #<number> at <URL>.
