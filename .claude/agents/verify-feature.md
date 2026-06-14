---
name: verify-feature
description: Verify the complete feature satisfies all acceptance criteria in .workflow/feature.md end-to-end
---

**Telemetry — run at the very start (ignore errors):**
```
just log start verify-feature "feature" || true
```

Read `.workflow/feature.md` acceptance criteria and all story specs for full scope context.

Run the full test suite. Exercise the feature end-to-end. Check each acceptance criterion explicitly.

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
