<!-- independent-review -->

## Independent review — APPROVED (round 1)

**Verdict: APPROVED — no blocking findings.**

### What the change does

Both `MapQuizView` and `MapLearningQuizView` changed their `@State private var position: MapCameraPosition` initial value from `.automatic` to `.region(MKCoordinateRegion())`. The fix exploits a structural invariant: the `Map` view only enters the SwiftUI view hierarchy when `session != nil`, and `session` is only set (inside `buildSession()`, called from `.onAppear`) after `position` has already been set to `.region(s.mapRegion)` with the correct candidate-pin region. The zero-span sentinel is never seen by MapKit in the normal flow.

### Angles checked

- **Line-by-line diff scan**: The change is mechanically correct. The one-liner substitution plus comment is applied symmetrically in both files.
- **Removed behavior**: `.automatic` was never semantically correct here. It was accidentally acceptable for country quizzes (local borders) but caused continental zoom-out for river/mountain/sea quizzes. No post-init code path ever reverts to `.automatic`.
- **Cross-file callers**: No callers can override the initial position (it is fully-internal `@State`). Session types guarantee non-zero `mapRegion` when cards are non-empty. `cameraBounds(for:)` is only called after `session != nil`, which means `session.mapRegion` is already the correct non-zero value from `QuizRegionMath.region(fittingPins:)` (which enforces a 12 degree minimum span floor).
- **Empty-cards path**: Examined in detail. The empty-session + early-return structure means `quizBody` can render with a zero-span `mapRegion` in that corner case. However, this was identical behavior before and after the diff (pre-diff, `position = .automatic` and `session.mapRegion = .init()` in the same path). Not a regression introduced by this PR.
- **Altitude**: Fix is at the correct depth. Deeper alternatives (deferring overlay registration, `mapScope`, keyframe animation) would be far more invasive with no additional benefit given the structural guarantee that `session` is nil until `buildSession` runs.
- **CI**: All checks pass (Build and Test, Lint, gitleaks).

### Finding

**Non-blocking nit** (inline comment posted on `MapLearningQuizView.swift` line 32): The 8-line comment explaining why `.automatic` must not be used is duplicated verbatim in both files. Consider extracting `QuizRegionMath.safeInitialCameraPosition` as a named constant with the explanation in its doc comment. Not required to merge.
