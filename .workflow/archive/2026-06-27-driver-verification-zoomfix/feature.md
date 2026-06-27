# Feature: Driver-based workflow verification + map-quiz zoom-out fix

## Goal

Make the `just ui-walkthrough` XCUITest driver the **standard verification mechanism** in the
workflow agents, so every future feature automatically *navigates* the app and *inspects*
screenshots + accessibility dumps to catch bugs (crashes, unlocalized strings, missing/duplicated/
obscured controls) — instead of the current single-static-screenshot check. To prove the change
works end-to-end, this same feature also (a) adds a **pinch/zoom** action to the driver and
(b) **fixes a real bug** — the country map quiz can no longer zoom out — verifying that fix with the
newly-baked-in driver verification.

## Background / root causes (already investigated — do NOT re-derive)

- **Driver not wired into the workflow.** `grep -rni 'ui-walkthrough' .claude/agents/` returns
  nothing. `verify-story.md` / `verify-feature.md` still use the OLD method: `just launch-sim` →
  `just screenshot-sim` → inspect ONE static screenshot, and only when a spec opts in via a
  `## Visual Verification` section / visual ACs. They cannot tap, navigate, or read accessibility
  trees. The driver got used in recent features ONLY because it was requested per-run.
- **Driver lacks a zoom gesture.** `HanahuacUITests/UIActionScript.swift` actions are
  `tap` / `typeText` / `mapTap` / `swipe` / `scroll` / `wait` / `dumpTree` / `screenshot` — no
  pinch/zoom. So the driver currently cannot exercise map zoom.
- **Zoom-out bug.** Both `MapQuizView` and `MapLearningQuizView` use
  `Map(position:, bounds: QuizRegionMath.cameraBounds(for: session.mapRegion))`.
  `MapQuizRegionHelper.cameraBounds` sets `maximumDistance: cameraDistance(for: region) *
  cameraDistanceHeadroom` with `cameraDistanceHeadroom = 1.15` — capping the camera to ~15% past the
  initial framing, so the user cannot zoom out to orient on the world. The cap was added
  deliberately (to stop large river/sea/mountain overlay geometry from re-framing the camera, and to
  avoid hint leaks) — so the fix must relax zoom-out WITHOUT reintroducing those problems.

## Acceptance Criteria

- [ ] **AC1 — Bake the driver into `verify-story`.** Update `.claude/agents/verify-story.md` so any
      story touching `Hanahuac/Views/**` (user-visible) is verified by authoring a focused action
      script and running `just ui-walkthrough`, then inspecting the per-step **screenshots AND
      accessibility-element dumps** — not a single static screenshot. This becomes the default for
      view-touching stories (not gated solely on an opt-in `## Visual Verification` section). Keep a
      sensible fallback for environments where the sim is unavailable.
- [ ] **AC2 — Bake the driver into `verify-feature`.** Update `.claude/agents/verify-feature.md` to
      run a broader multi-screen walkthrough across the feature's affected flows (navigate + inspect
      dumps), replacing the single-screenshot end-to-end check.
- [ ] **AC3 — Make verification actively hunt for issues.** The updated agents must explicitly
      direct the verifier to look for the concrete bug classes (an **empty accessibility tree =
      crash/app-gone**, English/untranslated text while the UI is in another language, duplicated /
      missing / obscured / overlapping controls), and fail/loop-back when found — not merely confirm
      "matches the spec."
- [ ] **AC4 — Add a `pinch` (zoom) action to the driver.** Extend `UIActionStep`/`UIActionType`
      (new `pinch` case + `scale` and optional `velocity` fields), handle it in `UIDriverTests` via
      `XCUIElement.pinch(withScale:velocity:)` (scale < 1 = zoom out, > 1 = zoom in) targeting the
      resolved element or the map (`map.tapCountry`), and document it in
      `.workflow/ui-walkthrough/README.md`. Unresolvable target is skipped (consistent with other
      actions), artifact capture continues.
- [ ] **AC5 — Fix the country map-quiz zoom-out.** The user can zoom out far enough to orient
      (continental/world view) on the country map quiz, while the **initial framing stays on the
      candidate-pin region**. Relax/raise the `maximumDistance` cap (and headroom) in
      `MapQuizRegionHelper.cameraBounds`. Constraints: do NOT reintroduce automatic overlay-driven
      re-framing of the *initial* camera; do NOT leak which pin is the answer (framing stays derived
      from all candidate pins). Apply coherently across the shared helper
      (`MapQuizView` + `MapLearningQuizView`); default to enabling zoom-out for all map-quiz
      categories (orientation helps everywhere) unless a category-specific reason emerges. Add/adjust
      `MapQuizRegionHelper` unit tests for the new zoom-out range.
- [ ] **AC6 — Prove the workflow change on the zoom fix (the test).** Demonstrate the new
      driver-based verification on AC5: author an action script that uses the new `pinch` action to
      zoom OUT on the country map quiz, run it via `just ui-walkthrough`, and confirm from the
      artifacts that zoom-out now works (e.g. the visible map span/region grows after the pinch).
      Capture the evidence and reference it in the verify log. This is the end-to-end proof that the
      baked-in driver verification catches/validates real behavior.

## Constraints

- **IN-PLACE run, NO worktree.** This modifies workflow tooling (`.claude/agents/`), so per the
  orchestrator Step-0 guard it must run in the primary checkout on a feature branch (a worktree
  would carry stale committed agent files). Still export `HANA_FEATURE_SLUG`.
- **Sequencing:** land the agent-verification update (AC1–AC3) and the driver `pinch` action (AC4)
  **before** the zoom-fix story (AC5/AC6), so the zoom fix is verified by the new mechanism. The
  zoom-fix story must use `just ui-walkthrough` + the new `pinch` action in its verification
  regardless of any agent-definition caching.
- iOS Simulator (iPhone 17 / iOS 26.5); project generated from project.yml via `just generate`
  (xcodegen) — never hand-edit pbxproj; `just lint` + `just test` must pass.
- Conventions (CLAUDE.md): Read/Grep/Glob over shell; allowlistable Bash shapes; `git commit -F`;
  `gh pr create --body-file`; bot actions via `scripts/gh-review-bot.sh`; the merge gate is the
  App-posted `code-owner-review` check (SHA-bound — re-post on head change); author must not
  self-approve.

## Out of Scope

- A vector / non-MapKit map redesign (satellite base stays; this is a camera-bounds fix only).
- New quiz modes, categories, or unrelated app features.
- Reworking the driver beyond adding the `pinch` action.
