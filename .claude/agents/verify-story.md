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

Ensure the local repo is on `main` and up to date before verifying (the PR may have been merged by the user):
```sh
git checkout main && git pull origin main
```

If the story modified any `@Model` type, boot the simulator and uninstall the app before running tests to avoid a stale-schema crash:
```sh
xcrun simctl boot "iPhone 17" 2>/dev/null || true
xcrun simctl uninstall booted com.hanahuac.app 2>/dev/null || true
```

For each criterion: run tests if the story touches Swift source files, inspect implementation, exercise the app if applicable. For pure tooling/config/workflow stories (no Swift files changed), skip `just test` — verify the criteria directly by inspecting the changed files and confirming they match the spec.

---

## Visual Verification

If `<story-dir>/spec.md` contains a `## Visual Verification` section, perform the following steps after the functional checks above. If no such section exists, skip this entire block (pure tooling stories do not need visual verification).

**Visual verification steps:**

1. **Boot simulator** (no-op if already booted):
   ```sh
   just boot-sim
   ```

2. **Build and install the app** to the simulator:
   ```sh
   just install-sim
   ```

3. **Launch the app:**
   ```sh
   just launch-sim || {
     BUNDLE=$(grep -m1 'PRODUCT_BUNDLE_IDENTIFIER' Hanahuac.xcodeproj/project.pbxproj | sed 's/.*= "//;s/";//')
     xcrun simctl launch booted "$BUNDLE"
   }
   sleep 2
   ```

4. **Take a screenshot** and save it:
   ```sh
   mkdir -p .workflow/screenshots/<story-id>
   just screenshot-sim .workflow/screenshots/<story-id>/verify-1.png
   ```

5. **Inspect the screenshot** using Claude's vision against the expected behavior described in the `## Visual Verification` section of `<story-dir>/spec.md`.

6. **If visual check passes:** proceed to mark the story done (see Outcomes below).

7. **If visual check fails:**
   a. Log the failure in `<story-dir>/log.md`: `<timestamp> visual-verify: FAILED attempt 1 — <description of what was wrong>`
   b. Attempt a targeted fix: diagnose the root cause from the screenshot, edit the relevant source file(s), rebuild (step 2), re-launch (step 3), take a new screenshot (save as `verify-2.png`), re-inspect.
   c. If the second attempt passes: proceed to mark the story done.
   d. If the second attempt also fails: log it in `<story-dir>/log.md`. Output STATUS: FAILED with visual failure details so the story loop can re-run implement-story with this context.

---

## Outcomes

- **All checks pass (functional + visual if applicable)** → update `<story-dir>/status.md` to `status: done`, mark story checked in `.workflow/stories.md`.
  Append to log. Run (ignore errors): `just log end verify-story "<story-id>" <R> <W> <E> <B> <est_chars> "DONE" || true`. Output STATUS: DONE.
- **Any check fails** → list failures in `<story-dir>/log.md`. Run (ignore errors): `just log end verify-story "<story-id>" <R> <W> <E> <B> <est_chars> "FAILED" || true`. Output STATUS: FAILED: <list>.
