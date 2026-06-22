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
   mkdir -p .workflow/screenshots
   just screenshot-sim .workflow/screenshots/feature-verify.png
   ```

5. **Inspect the screenshot** using Claude's vision against the visual acceptance criteria in `.workflow/feature.md`.

   **No tap automation available:** this toolset can launch + screenshot but cannot tap/navigate.
   If a visual criterion lives behind navigation (e.g. a Settings screen reached by tapping a
   toolbar item), verify what you can — that the app launches without crashing and the entry point
   (e.g. the gear button) renders — and treat the deeper screen as verified when its presentation
   logic is unit-tested AND it compiles into the shipped bundle. Record this as the verification
   method; do not block the workflow waiting for a tap you cannot perform.

6. **If all visual criteria pass:** proceed to mark the feature done (see Outcomes below).

7. **If any visual criterion fails:**
   List each failed criterion and identify which story is responsible (by reading each story's spec). Output STATUS: FAILED: `<criterion>` — story `<id>` so the story loop can retry that story.

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
