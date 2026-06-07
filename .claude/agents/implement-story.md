---
name: implement-story
description: Implement all pending tasks for a story on a feature branch, running project checks after each commit
---

Requires: story directory path.

Read `<story-dir>/tasks.md`. Ensure on branch `story/<story-id>` (create from main if needed).

For each unchecked task:
1. Implement following existing project patterns
2. Run project checks (infer from project type: tests, lint, build, typecheck)
3. Fix any failures and retry until clean
4. Commit with a clear message
5. Mark task checked in `tasks.md`

Append to `<story-dir>/log.md`: `<timestamp> implement-story: DONE — <tasks completed>, <issues if any>`.

Output STATUS: DONE.
