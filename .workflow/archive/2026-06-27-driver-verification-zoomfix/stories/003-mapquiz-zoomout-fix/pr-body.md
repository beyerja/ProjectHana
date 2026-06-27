## Goal

Let users zoom out far enough to orient themselves (continental/world view) on the country
map quiz, while keeping initial framing on the candidate-pin region — fixing the real
zoom-out bug — and prove the fix end-to-end with the newly baked-in, `pinch`-capable
`ui-walkthrough` driver verification (AC5 + AC6).

## Changes

### AC5 — relax the zoom-out cap (`MapQuizRegionHelper`)
- Raised `cameraDistanceHeadroom` from `1.15` → `16.0` so the derived `maximumDistance`
  (the zoom-OUT cap) allows a continental/world view.
- Initial framing is unchanged: `centerCoordinateBounds` is still derived from **all**
  candidate pins, so there is no answer-pin hint leak.
- No overlay-driven initial re-framing is reintroduced (the cap originally existed to stop
  river/sea/mountain overlay geometry from re-framing and leaking hints).
- Centralized in the shared helper consumed by both `MapQuizView` and
  `MapLearningQuizView`, so the change applies coherently to both.
- Zoom-out is enabled for all map-quiz categories by default.

### Tests
- Revised the `MapQuizRegionHelperTests` cap test: it now asserts the cap allows
  continental zoom-out (rather than the old tight cap).
- Added a headroom test and an initial-framing-unchanged test.
- `just lint` and `just test` pass.

### AC6 — driver proof
- Added `.workflow/ui-walkthrough/scripts/006-mapquiz-zoomout.json`, which uses the new
  `pinch` action (`scale 0.25` = zoom out) to drive the country map quiz.
- Driver evidence (visible map span growing after the pinch) is captured during
  verify-story via `just ui-walkthrough`.

## Dependencies
- Depends on Story 001 (#195, `pinch` driver action) — merged.
- Depends on Story 002 (#197, baked-in driver verification) — merged.

## Test plan
- [ ] `just lint` passes
- [ ] `just test` passes (incl. revised + new `MapQuizRegionHelperTests`)
- [ ] `just ui-walkthrough` with `006-mapquiz-zoomout.json` shows the visible map span
      grows after the zoom-out pinch on the country map quiz
- [ ] Manual check: initial framing still covers the candidate-pin region with no
      answer-pin hint leak

🤖 Generated with [Claude Code](https://claude.com/claude-code)
