# Feature: Fix isPinching Never Reset on Gesture Cancellation

## Goal
In `MapQuizView` and `MapLearningQuizView`, the `isPinching` flag can become permanently stuck at `true` if a pinch gesture is cancelled mid-flight (e.g. app backgrounded during a pinch). When stuck, all pin taps are blocked for the rest of the session. The fix must ensure `isPinching` is always reset to `false` when a pinch gesture is interrupted or cancelled.

## Acceptance Criteria
- [ ] `isPinching` is reset to `false` whenever a pinch gesture is cancelled or interrupted (not just on `onEnded`) in `MapQuizView`
- [ ] `isPinching` is reset to `false` whenever a pinch gesture is cancelled or interrupted (not just on `onEnded`) in `MapLearningQuizView`
- [ ] Pin taps work immediately after app foreground following a mid-pinch backgrounding event (no stuck `isPinching = true`)
- [ ] Normal pinch-to-zoom behaviour is unaffected: pin taps remain blocked while a pinch is actively in progress
- [ ] Existing unit tests pass
- [ ] New unit or UI test (or code comment with documented manual test steps) covers the cancellation scenario

## Constraints
- iOS / SwiftUI — must not use UIKit gesture recogniser APIs unless no SwiftUI alternative exists
- Change must be minimal and surgical; no unrelated refactoring
- Both files must be fixed identically (same pattern)

## Out of Scope
- Refactoring the gesture handling beyond the cancellation fix
- Changes to zoom scale logic or map pan gestures
- Any UI redesign of the quiz views
