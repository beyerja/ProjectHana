---
name: verify-feature
description: Verify the complete feature satisfies all acceptance criteria in .workflow/feature.md end-to-end
---

**Telemetry — run at the very start (ignore errors):**
```
just log start verify-feature "feature" || true
```

**Telemetry note string:** the final `notes` argument to `just log end` is passed through the
shell unquoted by `just`, so any `;`, `&`, `|`, or `()` in it will be parsed as shell syntax and
break the call (e.g. `bash: CI: command not found`). Keep the note a single short hyphen/space
token (e.g. `"all-AC-pass-CI-green"`), with no semicolons or parentheses.

Read `.workflow/feature.md` acceptance criteria and all story specs for full scope context.

**Checking merged feature files — use `origin/main`, not the working tree.**
When verifying that a feature's code is present after its PR merged, do NOT read files from the
primary checkout's working tree (`/Users/Private/Documents/Code/ProjectHana/`). That local `main`
may be diverged/stale and will make the feature appear absent even after a successful merge.
Always use `git -C <primary-checkout> show origin/main:<relative-path>` to read the authoritative
post-merge state. Example:
```sh
git -C /Users/Private/Documents/Code/ProjectHana show origin/main:Hanahuac/SomeFile.swift
```
`origin/main` is the source of truth once a PR merges; the local working tree is not.

Run the full test suite. Exercise the feature end-to-end. Check each acceptance criterion explicitly.

**Beware green checks that degrade-to-pass.** A passing gate is only meaningful if it actually
exercised the thing it claims to cover. Two known blind spots on this repo:
- The static l10n completeness gate hardcodes its locale list, so a locale added by a *different*
  feature (merged into `main` during this run) is invisible to it.
- The runtime locale-completeness XCTest no-ops in CI because the ODR pack bundle isn't mounted, so it
  reads empty and passes vacuously.
Whenever the feature touched localization, **independently diff every on-disk `Hanahuac/*.lproj`
against the base locale** (don't trust the gate alone) and confirm no locale is missing this feature's
keys. Generalize the instinct: when a criterion rides on an auto-pass-on-empty check, verify it by a
second, direct means.

---

## Visual Verification

If `.workflow/feature.md` contains a `## Acceptance Criteria` section with any visual criteria (criteria that reference UI behavior, screenshots, overlays, colors, gestures, animations, or other user-visible outcomes), perform the following visual end-to-end check after the functional/test checks above. If the feature is purely tooling/workflow with no visual criteria, skip this block.

**Driver walkthrough across the feature's affected flows (default):**

The end-to-end visual check is a broad **multi-screen** `just ui-walkthrough` run — *navigate* across
every screen the feature touched and inspect per-step screenshots AND accessibility dumps — not a
single static end-to-end screenshot.

1. **Boot simulator** (no-op if already booted):
   ```sh
   just boot-sim
   ```
   If the simulator cannot be booted, use the **sim-unavailable fallback** below.

2. **Author a multi-screen action script.** Read the affected story specs to enumerate every flow the
   feature changed, then write a JSON array to `.workflow/ui-walkthrough/scripts/feature.json` (use the
   **Write** tool) with `tap`/`scroll`/`mapTap`/`typeText`/`pinch` steps that **navigate across each
   affected screen** in turn (with `wait` between transitions), so one run spans the whole feature. The
   action-script schema, targeting order, and full action set (including the story-001 `pinch` zoom
   action) live in `.workflow/ui-walkthrough/README.md` — read it before authoring. A screenshot **and**
   accessibility dump are captured after *every* step.

3. **Run the driver** (each run is a compiled `xcodebuild test` cycle of ~tens of seconds, not a live
   session):
   ```sh
   just ui-walkthrough .workflow/ui-walkthrough/scripts/feature.json feature
   ```
   The recipe prints the resolved artifact directory (`.workflow/ui-walkthrough/feature/`).

4. **Inspect EVERY per-step artifact** in the printed run dir against the visual acceptance criteria in
   `.workflow/feature.md` — each `NNN-step.png` with Claude's vision and each `NNN-step.json`
   accessibility-element dump — covering every affected screen, not one screenshot.

5. **Hunt for concrete bug classes** while inspecting (see *Issue hunting* below).

6. **If all visual criteria pass** (and no issue-class hit): proceed to mark the feature done (see Outcomes below).

7. **If any visual criterion fails, or any *Issue hunting* class is detected:**
   List each failed criterion / detected issue and identify which story is responsible (by reading each
   story's spec). Output STATUS: FAILED: `<criterion>` — story `<id>` so the story loop can retry that story.

### Issue hunting — actively look for these bug classes

Inspect the per-step artifacts for the following and **FAIL** — attributing each to the responsible
story — the moment any is found; do not pass a feature that merely "matches the spec":

- **Empty accessibility tree = crash / app gone.** If any `NNN-step.json` is empty or has no app
  elements, the app crashed or never launched at that step. Hard fail.
- **Untranslated text.** English / source-language strings showing while the UI locale is set to
  another language — a missing-translation defect.
- **Duplicated, missing, obscured, or overlapping controls.** Two of a control that should appear once,
  a required control absent from the dump, a control hidden behind another, or overlapping frames.

When found, output STATUS: FAILED: `<criterion-or-issue>` — story `<id>` (per-criterion / per-story
attribution, matching the outcome format below) so the responsible story is retried.

### Sim-unavailable fallback

This toolset's driver needs a simulator. If `just boot-sim` / `just install-sim` cannot run, do **not**
block the workflow. Fall back to launch + a single screenshot inspected with vision. `.workflow/screenshots/`
is gitignored and `screenshot-sim` does not create its parent dir, so create it first:
```sh
mkdir -p .workflow/screenshots
just screenshot-sim .workflow/screenshots/feature-verify.png
```
For any criterion that lives behind
navigation you cannot drive, verify what you can (the app launches without crashing and the entry point
renders) and treat the deeper screen as verified when its presentation logic is unit-tested AND it
compiles into the shipped bundle. Record the verification method used.

---

## Outcomes

- **All pass (functional + visual if applicable)** → run (ignore errors): `just log end verify-feature "feature" <R> <W> <E> <B> <est_chars> "DONE" || true`. Append to `.workflow/log.md`: `<timestamp> verify-feature: DONE`.
  Then build and install to /Applications so the user's local app is current:
  ```sh
  just install
  ```
  Output STATUS: DONE.
- **Any fail** → run (ignore errors): `just log end verify-feature "feature" <R> <W> <E> <B> <est_chars> "FAILED" || true`. List each failed criterion and identify which story is responsible.
  Output STATUS: FAILED: <criterion> — story <id>.
