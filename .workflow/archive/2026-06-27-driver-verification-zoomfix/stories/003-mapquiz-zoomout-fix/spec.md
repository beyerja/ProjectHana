# Story 003 — Fix country map-quiz zoom-out + prove it with the driver

## Title
Relax the map-quiz zoom-out cap in `MapQuizRegionHelper` and verify with the
`pinch`-enabled `ui-walkthrough` driver

## Goal
Let the user zoom out far enough to orient (continental/world view) on the country map
quiz, while keeping initial framing on the candidate-pin region — fixing the real bug —
and prove the fix end-to-end with the newly baked-in, `pinch`-capable driver
verification. This is the end-to-end proof that the workflow change (Stories 001+002)
catches/validates real behavior.

## Scope (AC5, AC6)
- **AC5 — fix the zoom-out:** Relax/raise the `maximumDistance` cap (and
  `cameraDistanceHeadroom`) in `MapQuizRegionHelper.cameraBounds` so the camera can
  zoom out to a continental/world view. Apply coherently across the shared helper used
  by both `MapQuizView` and `MapLearningQuizView`. Constraints:
  - Initial framing stays on the candidate-pin region (derived from **all** candidate
    pins — do NOT leak which pin is the answer).
  - Do NOT reintroduce automatic overlay-driven re-framing of the *initial* camera
    (the cap was originally added to stop river/sea/mountain overlay geometry from
    re-framing and to avoid hint leaks).
  - Default to enabling zoom-out for all map-quiz categories unless a category-specific
    reason emerges.
  - Add/adjust `MapQuizRegionHelper` unit tests for the new zoom-out range.
- **AC6 — prove with the driver:** Author an action script that uses the new `pinch`
  action (Story 001) to zoom OUT on the country map quiz, run it via
  `just ui-walkthrough`, and confirm from the artifacts that zoom-out now works (visible
  map span/region grows after the pinch). Capture the evidence and reference it in the
  verify log. Verification MUST use `just ui-walkthrough` + the new `pinch` action
  regardless of any agent-definition caching.

## Acceptance Criteria
- [ ] On the country map quiz, the user can zoom out to a continental/world view; the
      `maximumDistance`/headroom cap in `MapQuizRegionHelper.cameraBounds` is relaxed.
- [ ] Initial framing stays on the candidate-pin region (derived from all candidate
      pins) — no answer-pin hint leak, no automatic overlay-driven initial re-framing.
- [ ] Change applies coherently to both `MapQuizView` and `MapLearningQuizView` via the
      shared helper; zoom-out enabled for all map-quiz categories by default.
- [ ] `MapQuizRegionHelper` unit tests added/adjusted for the new zoom-out range; pass.
- [ ] An action script using the new `pinch` action zooms OUT on the country map quiz
      via `just ui-walkthrough`; artifacts show the visible map span grows; evidence is
      referenced in the verify log.
- [ ] `just lint` and `just test` pass.

## Dependencies
- **Depends on Story 001** (the `pinch` driver action — required for AC6 verification).
- **Depends on Story 002** (the baked-in driver verification flow in the agents).
Per the feature sequencing constraint, Stories 001 and 002 MUST land before this story.

## Notes
- Read/Grep/Glob over shell; allowlistable Bash shapes only. Do NOT hand-edit pbxproj.
- Out of scope: vector/non-MapKit redesign; new quiz modes/categories.
