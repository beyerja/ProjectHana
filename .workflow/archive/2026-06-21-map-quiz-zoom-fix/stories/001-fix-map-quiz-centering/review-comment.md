<!-- independent-review -->
## Independent review — APPROVED (round 1)

Fresh cold-context 4-eye review of PR #143 against `spec.md`.

**Verdict: APPROVED.** No blocking findings. Formal bot approval submitted.

### Acceptance criteria
- **AC1 root cause confirmed in code + documented** — log.md traces the camera path in both views, rules out region-math / lat-lon-swap / data errors, and confirms the mechanism: bare `Map(position:)` with no `bounds:` lets SwiftUI reconcile the requested region against the content union (full-course river `linePath`, large sea/mountain `borderRings`), framing the giant overlay extent. Country works because its borders are small/local. ✅
- **AC2/AC3 framing from full bbox, no hint leak** — `cameraBounds(for:)` derives purely from `session.mapRegion`, whose center is the candidate-pin bounding-box center (answer-independent). The correct pin is not centered, zoomed-to, or distinguished. ✅
- **AC4 zoom unchanged except where needed** — only `maximumDistance` (zoom-out cap) is added; min-zoom / pinch behaviour is untouched. ✅
- **AC5 shared logic, no per-category branch** — one `cameraBounds(for:)` serves all four categories and is wired identically into both `MapQuizView` and `MapLearningQuizView`. ✅
- **AC6 regression test** — weakly met. The one load-bearing assertion (`cap < overlayExtentMeters`) genuinely fails if the cap is loosened to overlay scale. Two of the three assertions are tautological against their own re-derivation of the formula (see inline). The original defect is view-level and `MapCameraBounds`' opaque API can't be unit-tested directly, so a math proxy is reasonable — just trim the no-op checks. Non-blocking. ✅ (weak)
- **AC7 CI green** — Build & Test, Lint (all languages), gitleaks all pass. ✅

### Mechanism correctness
`MapCameraBounds(centerCoordinateBounds: region)` pins the camera center inside the candidate-pin region — the load-bearing constraint that stops the "panned to the opposite side" symptom — while `maximumDistance` caps zoom-out so the overlay extent can't re-frame. Sound, at the right altitude.

### Non-blocking notes (posted inline)
1. Two new test assertions are tautological (re-derive the same formula they check); keep `cap < overlayExtentMeters`.
2. `maximumDistance` is MapKit camera-to-center distance, not ground span; `cameraDistance(for:)` feeds ground-extent metres directly. Approximate but adequate given headroom + region padding. Worth a doc note.

`mergeStateStatus: BLOCKED` is the main-branch code-owner ruleset gate awaiting approval; the formal bot approval addresses it.
