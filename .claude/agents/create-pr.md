---
name: create-pr
description: Push the story branch and open a PR against main with a description derived from the story spec
---

Requires: story directory path.

Read `<story-dir>/spec.md` and recent commits. Push the current branch.

Create a PR targeting main:
- Title: story title
- Body: goal, summary of changes, how to test

Write PR URL and number to `<story-dir>/pr.md`.
Append to `<story-dir>/log.md`: `<timestamp> create-pr: DONE — <URL>`.

Output STATUS: DONE.
