---
name: verify-story
description: Verify every acceptance criterion in a story spec is satisfied after implementation
---

Requires: story directory path.

Read `<story-dir>/spec.md` acceptance criteria.

For each criterion: run tests, inspect implementation, exercise the app if applicable.

- **All pass** → update `<story-dir>/status.md` to `status: done`, mark story checked in `.workflow/stories.md`.
  Append to log. Output STATUS: DONE.
- **Any fail** → list failures in `<story-dir>/log.md`. Output STATUS: FAILED: <list>.
