<!-- independent-review -->
## Independent review — Round 1: APPROVED

Cold-context 4-eye review of the diff (head `72841eb`) against the Story 003 acceptance criteria (AC5/AC6). No blocking findings; three non-blocking nits posted inline.

### Spec constraints verified against the diff
- **Initial framing genuinely unchanged.** `cameraBounds(for:)` still passes `centerCoordinateBounds: region` untouched; the diff only multiplies `cameraDistance(for:)` by the new headroom for `maximumDistance`. Region derivation (`region(fittingPins:)` over **all** candidate pins, bounding-box center) is not altered — no answer-pin hint leak.
- **No overlay-driven initial re-framing reintroduced.** Only the manual zoom-OUT cap moved; the starting camera is still pinned to the candidate-pin region.
- **`minimumDistance` (zoom-IN cap) unchanged.** It is never set anywhere in the helper — left at MapKit's default, confirmed by grep across the MapQuiz dir.
- **Headroom 16.0 is sane and shared.** Applied via the single `cameraDistanceHeadroom` constant consumed by both `MapQuizView` (`:64`) and `MapLearningQuizView` (`:86`); not category-specific, enabled for all categories by default. 16x the fitted span clears a ~60° continental overlay extent (asserted in the test) without being absurd.
- **Pinch path is a genuine gesture.** The local `just ui-walkthrough` (iOS Simulator) AC6 evidence path uses the native `element.pinch(withScale:velocity:)` — a real zoom-out at `scale 0.25`. The `pinch` action is fully wired in the driver dispatch with correct velocity-sign handling.
- **Tests assert real behavior.** New/revised tests assert the relaxed cap (`cap == framedSpan * headroom`, `cap > overlay extent`), the headroom floor (`>= 12.0`), and that initial framing (center + pin containment) is unchanged — not vacuous.

### Non-blocking nits (posted inline)
1. **Mac Catalyst pinch is effectively sequential.** The `#if targetEnvironment(macCatalyst)` fallback fires two blocking `press(…thenDragTo:…)` calls in sequence, so it is not a true simultaneous two-finger pinch and won't zoom on Catalyst. Not blocking — that branch's job on CI is compile + not-crash, and it is not the AC6 evidence path — but the doc comment claiming "two simultaneous press-drag gestures" overstates it.
2. **Vacuous smoke line.** `_ = QuizRegionMath.cameraBounds(for: region)` discards the result while the comment claims it guards `centerCoordinateBounds`/`minimumDistance`; nothing is asserted on those. Trim the comment or assert what is observable.
3. **Dual-unit spread math.** `startSpread`/`endSpread` fractions × bare `* 100` invite a silent off-by-100 next to the genuine `withNormalizedOffset` above; express endpoints directly in points.

CI is green on this head. Verdict: **APPROVED** — ready for the code-owner-review submission step. (This review does not set the formal merge-gate check.)
