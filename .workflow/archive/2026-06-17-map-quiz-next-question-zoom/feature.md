# Feature: Fix map quiz zoom so all pins are visible on each new question

## Status
Clarified (final — provided by user, no further clarification needed).

## Problem
On the map quiz, switching to the next quiz question produces a wrong zoom/region that
often does not include all the pins for the new question.

## Root cause
In `Hanahuac/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift`, `quizRegion(for:correct:)`:
- Builds the span from the bounding box of all features (`lats.max() - lats.min()`, etc.)
  with a 1.6x padding factor and a 20° floor.
- Then centers the region on the **correct feature's** coordinate (not the bounding-box
  center) and applies a random ±30%-of-span center offset.

Because the region is centered on the target feature rather than the bounding-box center,
and the span does not budget for the random offset, pins are pushed outside the viewport.
The span also does not correct for the map's screen aspect ratio or for latitude
compression (longitude degrees shrink with latitude), so wide spreads clip horizontally
on portrait phones.

## Shared logic and call sites (all must be covered)
`makeQuizAnnotations(correct:allFeatures:neighbourCount:)` in `MapQuizRegionHelper.swift`
produces `(features, region)`. It is consumed by:
- `Hanahuac/Views/Quiz/MapQuiz/MapQuizSession.swift` (used by `MapQuizView`)
- `Hanahuac/Views/Quiz/MapQuiz/MapLearningSession.swift` (used by `MapLearningQuizView`)

Both store the result in `mapRegion` and drive a `MapCameraPosition`. Fixing the shared
helper covers both views in one place. Both views overlay a top **promptBanner** and a
bottom **feedbackBanner** over the `Map`, so pins near the top/bottom edges can be hidden
under those overlays.

## Decisions (final)
1. Keep a randomized look but **clamp the jitter** so all pins remain guaranteed visible.
   Center on the **bounding box** of all pins, size the span to fit them all, and only
   allow jitter up to the amount that still keeps every pin on screen.
2. Padding: choose a sensible margin around the outermost pins (~15–20%) **plus** insets
   so pins aren't hidden under the top prompt banner or bottom feedback banner overlays.
3. **Correct the span for device/map aspect ratio and latitude** so wide pin spreads do
   not clip horizontally on portrait phones.
4. Apply the fix to **all map quiz usages**, not just `MapQuizView` — i.e. the shared
   region logic, covering `MapLearningQuizView` as well.

## Acceptance criteria
- For every quiz question (across both `MapQuizView` and `MapLearningQuizView`), the
  computed region's visible rect contains **all** annotation pins for that question, with
  a comfortable margin, on portrait phone aspect ratios.
- Pins are not hidden under the top prompt banner or bottom feedback banner (vertical
  inset budgeted into the region).
- The region still varies between questions (jitter preserved) but jitter is clamped so
  it can never push a pin off-screen or under a banner.
- Span accounts for map aspect ratio and latitude compression.
- Single-pin / degenerate cases (all pins coincident) produce a sane default span.
- Unit tests assert all pins fall within the visible region (including aspect/inset
  budget) for representative cases, including wide horizontal spreads on portrait aspect.
- App builds; fast CI checks pass.

## Out of scope
- Visual restyling of banners or pins.
- Changing neighbour selection logic / `neighbourCount`.
