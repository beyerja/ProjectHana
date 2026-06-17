# Story 001 — Clamp map-quiz region so all pins stay visible

## Goal
Rewrite the shared `quizRegion(for:correct:)` logic in
`Hanahuac/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift` so the region returned by
`makeQuizAnnotations` always contains every annotation pin for the question, on portrait
phone aspect ratios, while preserving a randomized (but clamped) look. This single change
covers both `MapQuizView` (via `MapQuizSession`) and `MapLearningQuizView` (via
`MapLearningSession`), which both consume `makeQuizAnnotations`.

## Approach
1. Compute the bounding box of ALL annotation features (not just the correct one).
2. Center the region on the **bounding-box center** (mean of min/max lat & lon).
3. Size the span to fit the bounding box plus a fractional margin (~15–20%) around the
   outermost pins.
4. Correct the span for:
   - **Latitude compression** — longitude degrees cover less ground at higher |latitude|;
     widen `longitudeDelta` (divide the geographic lon extent by cos(centerLat)) so the
     horizontal geographic extent maps correctly to screen.
   - **Map aspect ratio** — assume a portrait phone aspect (taller than wide). Ensure the
     final span's width:height degree ratio is at least the map's width:height so a wide
     pin spread does not clip horizontally. Use a conservative portrait aspect constant
     (documented) so we don't read live view geometry from the helper.
5. **Vertical inset budget** — the top prompt banner and bottom feedback banner overlay
   the map. Inflate `latitudeDelta` (or shift center) so pins are never hidden under those
   overlays. Use a documented inset fraction.
6. **Clamp jitter** — after sizing the span to fit all pins + margin, compute the maximum
   center offset that still keeps every pin (with margin/inset) inside the viewport, then
   pick a random offset within that clamped range. Jitter must never push a pin off-screen
   or under a banner.
7. Handle degenerate cases: empty features (return sane default), single pin / all-
   coincident pins (apply a sensible minimum span).

## Acceptance Criteria
- For representative feature sets (incl. wide horizontal spreads at high and low latitude,
  vertical spreads, single pin, coincident pins), the returned region's visible rect —
  accounting for the assumed portrait aspect ratio and banner insets — contains every
  annotation pin with margin to spare.
- Region center is derived from the bounding box, not the correct feature's coordinate.
- Jitter is preserved but clamped: across many random draws, no pin ever leaves the
  inset/aspect-adjusted visible rect.
- Span corrects for latitude compression and portrait aspect ratio.
- Both `MapQuizSession` and `MapLearningSession` get the improved region with no call-site
  changes required (or minimal, if a parameter is added — keep API stable if possible).
- New unit tests under the existing test target assert the above containment for the
  representative cases. Tests fail against the old implementation's behavior conceptually
  (i.e. they meaningfully exercise containment + clamping).
- `just` build + fast lint/test checks pass.

## Notes
- Keep the public signature of `makeQuizAnnotations` stable to avoid touching call sites,
  unless a small additive parameter (with a default) is clearly cleaner.
- Pure-function helpers (bounding box, span fitting, clamp) should be testable directly.
