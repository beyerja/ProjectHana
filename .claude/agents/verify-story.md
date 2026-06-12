---
name: verify-story
description: Verify every acceptance criterion in a story spec is satisfied after implementation
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start verify-story "<story-id>" || true
```

Read `<story-dir>/spec.md` acceptance criteria.

If the story modified any `@Model` type, boot the simulator and uninstall the app before running tests to avoid a stale-schema crash:
```sh
xcrun simctl boot "iPhone 17" 2>/dev/null || true
xcrun simctl uninstall booted com.private.ProjectHana 2>/dev/null || true
```

For each criterion: run tests, inspect implementation, exercise the app if applicable.

- **All pass** → update `<story-dir>/status.md` to `status: done`, mark story checked in `.workflow/stories.md`.
  Append to log. Run (ignore errors): `just log end verify-story "<story-id>" <R> <W> <E> <B> <est_chars> "DONE" || true`. Output STATUS: DONE.
- **Any fail** → list failures in `<story-dir>/log.md`. Run (ignore errors): `just log end verify-story "<story-id>" <R> <W> <E> <B> <est_chars> "FAILED" || true`. Output STATUS: FAILED: <list>.
