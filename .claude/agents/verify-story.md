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

Ensure you are verifying up-to-date code (the PR may have been merged by the user). **Worktree-aware:**
in a dedicated feature worktree you must NOT `git checkout main` (main is checked out in the primary
worktree, and switching would abandon this run's branch). Detect the situation and sync without
switching branches:
```sh
git fetch origin
if git worktree list --porcelain | grep -q "^worktree $(pwd -P)$" \
   && [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
    # Linked feature worktree — verify the branch (already contains the merged work), don't switch.
    git merge --ff-only origin/main 2>/dev/null || true
else
    git checkout main && git pull origin main
fi
```

If the story modified any `@Model` type, boot the simulator and uninstall the app before running tests to avoid a stale-schema crash:
```sh
xcrun simctl boot "iPhone 17" 2>/dev/null || true
xcrun simctl uninstall booted com.hanahuac.app 2>/dev/null || true
```

For each criterion: run tests if the story touches Swift source files, inspect implementation, exercise the app if applicable. For pure tooling/config/workflow stories (no Swift files changed), skip `just test` — verify the criteria directly by inspecting the changed files and confirming they match the spec.

---

## Visual Verification

**Trigger by changed files, not by an opt-in section.** If the story changed any file under
`Hanahuac/Views/**` (user-visible UI), the **default** verification is a `just ui-walkthrough` driver
run — *navigate* the app and inspect per-step screenshots AND accessibility dumps — regardless of
whether `<story-dir>/spec.md` has a `## Visual Verification` section. A `## Visual Verification`
section, when present, supplies the *expected behavior* to check against; its absence does not skip the
walkthrough for a view-touching story. Skip this entire block only when the story touched no
`Hanahuac/Views/**` files (pure tooling/config/data stories do not need visual verification).

Confirm whether the story touched views:
```sh
git diff --name-only origin/main...HEAD -- 'Hanahuac/Views' | head
```

**Driver walkthrough steps (default for view-touching stories):**

1. **Boot simulator** (no-op if already booted):
   ```sh
   just boot-sim
   ```
   If the simulator cannot be booted (no simulator available in this environment), use the
   **sim-unavailable fallback** below instead of failing the story.

2. **Author a focused action script** for what this story changed. Write a JSON array to
   `.workflow/ui-walkthrough/scripts/<story-id>.json` (use the **Write** tool) that *navigates* to and
   exercises the changed screen(s) — `tap`/`scroll`/`mapTap`/`typeText`/`pinch` steps, with `wait`
   between transitions. The action-script schema, targeting order, and the full action set (including
   the story-001 `pinch` zoom action) are documented in `.workflow/ui-walkthrough/README.md` — read it
   before authoring. A screenshot **and** accessibility dump are captured after *every* step, so cover
   each state the story affects.

3. **Run the driver** (each run is a compiled `xcodebuild test` cycle of ~tens of seconds, not a live
   session):
   ```sh
   just ui-walkthrough .workflow/ui-walkthrough/scripts/<story-id>.json <story-id>
   ```
   The recipe prints the resolved artifact directory (`.workflow/ui-walkthrough/<story-id>/`).

4. **Inspect EVERY per-step artifact** in the printed run dir — not one static screenshot:
   - each `NNN-step.png` with Claude's vision against the expected behavior, and
   - each `NNN-step.json` accessibility-element dump (type / label / identifier / value / frame).
   Step `000` is the initial post-launch state; `NNN` ascend per script step.

5. **Hunt for concrete bug classes** while inspecting the artifacts (see *Issue hunting* below) — do
   not merely confirm the UI "matches the spec."

6. **If the walkthrough passes** (all steps render correctly, no issue-class hit): proceed to mark the
   story done (see Outcomes below).

7. **If the walkthrough fails** (a step is wrong, or any *Issue hunting* class is detected):
   a. Log the failure in `<story-dir>/log.md`: `<timestamp> visual-verify: FAILED attempt 1 — <which step/artifact and what was wrong>`
   b. Attempt a targeted fix: diagnose the root cause from the screenshots/dumps, edit the relevant
      source file(s), rebuild + re-run the driver (step 3, reuse the same script), re-inspect.
   c. If the second attempt passes: proceed to mark the story done.
   d. If the second attempt also fails: log it in `<story-dir>/log.md`. Output STATUS: FAILED with the
      visual failure details so the story loop can re-run implement-story with this context.

### Issue hunting — actively look for these bug classes

Inspect the per-step artifacts for the following and **FAIL + loop back** (output STATUS: FAILED with
the specifics so implement-story re-runs) the moment any is found — do not pass a story that merely
"looks like the spec":

- **Empty accessibility tree = crash / app gone.** If any `NNN-step.json` is empty or has no app
  elements (only a bare window / nothing), the app crashed or never launched at that step. Hard fail.
- **Untranslated text.** English / source-language strings showing while the UI locale is set to
  another language (e.g. a Korean run still rendering English labels) — a missing-translation defect.
- **Duplicated, missing, obscured, or overlapping controls.** Two of a control that should appear
  once, a control the spec requires that is absent from the dump, a control hidden behind another, or
  overlapping frames in the accessibility dump.

### Sim-unavailable fallback

If `just boot-sim` / `just install-sim` cannot run (no simulator in this environment), do **not** block
the story loop. Fall back, in order of preference, to:
- the prior behavior — `just install-sim` then `just launch-sim` (or `xcrun simctl launch booted <bundle-id>`)
  and a single `just screenshot-sim .workflow/screenshots/<story-id>/verify-1.png` inspected with vision; or
- inspecting the unit-tested presentation logic for the changed views and confirming it compiles into
  the shipped bundle.
Record which verification method was used in `<story-dir>/log.md`.

---

## Outcomes

- **All checks pass (functional + visual if applicable)** → update `<story-dir>/status.md` to `status: done`, mark story checked in `.workflow/stories.md`.
  Append to log. Run (ignore errors): `just log end verify-story "<story-id>" <R> <W> <E> <B> <est_chars> "DONE" || true`. Output STATUS: DONE.
- **Any check fails** → list failures in `<story-dir>/log.md`. Run (ignore errors): `just log end verify-story "<story-id>" <R> <W> <E> <B> <est_chars> "FAILED" || true`. Output STATUS: FAILED: <list>.
