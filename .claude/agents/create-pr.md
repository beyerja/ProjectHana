---
name: create-pr
description: Push the story branch and open a PR against main with a description derived from the story spec
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start create-pr "<story-id>" || true
```

Read `<story-dir>/spec.md` and recent commits. Push the current branch:
```
export PATH="$HOME/.nix-profile/bin:$PATH"
git push -u origin <branch>
```

Create a PR targeting main using `gh`:
```
gh pr create --base main --head <branch> --title "<story title>" --body "..."
```
- Body: goal, bulleted summary of changes, test plan checklist
- Always pass body via HEREDOC to preserve formatting

Write PR URL and number to `<story-dir>/pr.md`.
Count tool calls (R/W/E/B) and estimate chars, then run (ignore errors):
```
bash scripts/agent-log.sh end create-pr "<story-id>" <R> <W> <E> <B> <est_chars> "" || true
```
Append to `<story-dir>/log.md`: `<timestamp> create-pr: DONE — <URL>`.

Output STATUS: DONE — PR #<number> at <URL>.
