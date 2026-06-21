# Feature: Fix broken map-quiz centering for river, mountain, and sea quizzes

## Status: clarified (clarify step COMPLETE — spec authoritative from user)

## Problem
The river, mountain, and sea map quizzes open centered on the wrong location. The
candidate pins (including the correct answer) are off-screen — "almost the complete
opposite side of the map" — so the user must scroll to find them. The COUNTRY quiz
frames its pins correctly and is the reference/control for correct behaviour. Both the
standalone Map Quiz view (`MapQuizView`) and the Map Learning view
(`MapLearningQuizView`) are affected; they share the region/centering logic.

## Scope
- `Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift`
- `Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift`
- Shared region/annotation/overlay logic:
  - `Hanahuac/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift` (`makeQuizAnnotations`, `QuizRegionMath`)
  - `Hanahuac/Views/Quiz/MapQuiz/MapFeatureRendering.swift` (`featureOverlays`)
  - `Hanahuac/Models/MappableFeature.swift` (pin coordinates per category)
- Fix the SHARED logic so both views benefit from one change. Do not introduce
  category-specific centering branches unless investigation proves a category genuinely
  needs different pin-source handling.

## Authoritative clarified spec (from user)
1. Scope: BOTH `MapQuizView` and `MapLearningQuizView`. Fix the shared region/centering math.
2. Categories: river, mountain, and sea all fail equally. Country works and is the control.
3. Symptom is WRONG CENTER, not wrong zoom. The zoom level looks fine; the map is panned
   to the wrong place. Fix the centering; do not change zoom behaviour unless centering
   requires it.
4. Frequency: treat as broadly broken — assume all sessions / all questions for the three
   categories are affected. (A stray working case is likely caching, not correctness.)
5. Acceptance bar (note the correction): every question in river/mountain/sea (and the
   matching country quiz) must open with ALL candidate pins visible on screen — including
   the correct answer — with NO manual scrolling. **The correct answer must NOT be
   centered or otherwise visually distinguished at open — that would leak which pin is
   correct.** The correct pin is simply somewhere within the visible region alongside the
   distractors. Framing must be derived from the full candidate-pin set (their bounding
   box), independent of which pin is the answer.

## Investigation findings (orchestrator — confirm exact mechanism in code before fixing)
The region math in `QuizRegionMath.region(fittingPins:)` is already correct and
well-tested: it centers on the bounding-box center of the candidate pins (independent of
the answer — see `testRegionCenterDerivedFromBoundingBoxNotCorrectFeature`), fits all pins
with margin/aspect/inset, and clamps jitter so no pin leaves the visible rect. Pin
coordinates per category (`MappableFeature.pinCoordinate`) and the bundled JSON
(`seas.json` etc.) are sane (no lat/lon swap or sign error found). So the computed
`mapRegion` is correct for all categories.

Leading root-cause hypothesis (CONFIRM in code, do not assume): the difference between
country (works) and river/sea/mountain (broken) is the **map overlay geometry**, not the
region math. `MapQuizView`/`MapLearningQuizView` render `featureOverlays` inside the
`Map` content builder:
- Countries: `borderRings` are small polygons local to their pins.
- Seas/mountains: `borderRings` polygons can be very large (e.g. ocean borders spanning a
  huge area).
- Rivers: `linePath` polylines follow the full real course, extending far beyond the pin
  bounding box.
When SwiftUI's `Map` resolves its displayed region with `position` set to
`.region(session.mapRegion)` but the content includes overlay geometry far outside that
region, the camera can end up framing the overlay extent (or otherwise not honouring the
intended region), pushing the candidate pins off-screen — matching the "opposite side of
the map" symptom precisely. The candidate fixes to evaluate:
- Ensure the intended `.region(mapRegion)` is authoritatively applied / re-applied so
  overlay geometry never overrides the camera (timing of `position` assignment vs. content
  appearance), and/or
- Constrain overlay influence on the camera.
Other possibilities to rule out while confirming: the `onAppear`/`buildSession` initial
`position` assignment racing the first content layout; the initial question (currentIndex
never changes, so no `onChange` re-applies the region).

Whatever the confirmed mechanism, the fix must keep the existing correct,
answer-independent framing and must NOT center on or visually distinguish the correct pin.

## Acceptance criteria
1. ROOT CAUSE is confirmed in code (not assumed) and documented in the story log: state
   exactly why river/mountain/sea mis-center while country does not.
2. For river, mountain, sea, AND country quizzes, in BOTH `MapQuizView` and
   `MapLearningQuizView`, every question opens with all candidate pins (correct + all
   distractors) inside the banner-free visible region — no manual scrolling needed.
3. The correct pin is NOT centered, NOT zoomed-to, and NOT otherwise visually
   distinguished at question open versus the distractors. Framing is derived from the full
   candidate-pin bounding box, independent of which pin is the answer.
4. Zoom behaviour is unchanged except where centering genuinely requires it.
5. The fix is in shared logic — one change path serves all categories and both views; no
   gratuitous per-category centering branch.
6. Automated test coverage: extend the existing `MapQuizRegionHelperTests` (or add a
   focused test) that would have caught this regression — e.g. assert that with
   river/sea/mountain candidate pins plus their large overlay geometry, the framing still
   contains every candidate pin (and the correct pin is not the region center). Country
   stays green.
7. `just lint` and `just test` pass. CI is green on the PR.

## Out of scope
- Changing pin coordinate data or per-category pin-source logic (unless investigation
  proves a coordinate bug — currently none found).
- Visual restyling of pins/overlays beyond what the centering fix requires.
- Country quiz behaviour changes (it is the working control; keep it working).
