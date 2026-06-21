# 001 — Fix map-quiz centering for river, mountain, and sea quizzes

## Title
Fix broken map-quiz centering so all candidate pins are framed for river, mountain, sea (and country), in both MapQuizView and MapLearningQuizView

## Goal
River, mountain, and sea map quizzes currently open panned to the wrong location — the
candidate pins (including the correct answer) land off-screen, near "the opposite side of
the map", forcing manual scrolling. Country quizzes frame correctly and are the control.
Both `MapQuizView` and `MapLearningQuizView` are affected and share the region/centering
logic.

Confirm the root cause in code, then fix the SHARED logic so every question in all four
categories opens with every candidate pin visible — framed from the full candidate-pin
bounding box, independent of which pin is the answer, with the correct pin neither centered
nor otherwise distinguished. Add regression coverage and keep `just lint` / `just test`
green.

Files in scope:
- `Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift`
- `Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift`
- `Hanahuac/Views/Quiz/MapQuiz/MapQuizRegionHelper.swift` (`makeQuizAnnotations`, `QuizRegionMath`)
- `Hanahuac/Views/Quiz/MapQuiz/MapFeatureRendering.swift` (`featureOverlays`)
- `Hanahuac/Models/MappableFeature.swift` (pin coordinates per category)
- `MapQuizRegionHelperTests` (regression coverage)

## Acceptance Criteria
1. **Root cause confirmed in code (not assumed)** and documented in the story log: state
   exactly why river/mountain/sea mis-center while country does not. The leading hypothesis
   to confirm or refute is overlay geometry (large sea/mountain `borderRings`, full-course
   river `linePath`) overriding the `Map` camera versus the intended `.region(mapRegion)`,
   and/or the initial `position` assignment racing first content layout. Rule out the other
   listed possibilities while confirming.
2. For **river, mountain, sea, AND country** quizzes, in **BOTH** `MapQuizView` and
   `MapLearningQuizView`, every question opens with all candidate pins (correct + every
   distractor) inside the banner-free visible region — no manual scrolling needed.
3. The correct pin is **NOT centered, NOT zoomed-to, and NOT otherwise visually
   distinguished** at question open versus the distractors. Framing is derived from the full
   candidate-pin bounding box, independent of which pin is the answer.
4. Zoom behaviour is unchanged except where centering genuinely requires it.
5. The fix lives in **shared logic** — one change path serves all categories and both views;
   no gratuitous per-category centering branch (a category-specific branch is allowed only if
   investigation proves a category genuinely needs different pin-source handling).
6. **Regression test added**: extend `MapQuizRegionHelperTests` (or add a focused test) that
   would have caught this regression — e.g. assert that with river/sea/mountain candidate
   pins plus their large overlay geometry, the framing still contains every candidate pin and
   the correct pin is not the region center. Country stays green.
7. `just lint` and `just test` pass; CI is green on the PR.

## Out of scope
- Changing pin coordinate data or per-category pin-source logic (unless investigation proves
  a coordinate bug — currently none found).
- Visual restyling of pins/overlays beyond what the centering fix requires.
- Country quiz behaviour changes (it is the working control; keep it working).
