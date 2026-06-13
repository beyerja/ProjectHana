# Story 001: Fix isPinching never reset on gesture cancellation

## Goal
Ensure `isPinching` is always reset to `false` when a `MagnificationGesture` is cancelled or interrupted in both `MapQuizView` and `MapLearningQuizView`, so pin taps are never permanently blocked within a session.

## Acceptance Criteria
- [ ] `MagnificationGesture` in `MapQuizView` resets `isPinching = false` on cancellation / interruption, not only on `onEnded`
- [ ] `MagnificationGesture` in `MapLearningQuizView` resets `isPinching = false` on cancellation / interruption, not only on `onEnded`
- [ ] Pin taps are functional immediately after returning from background mid-pinch
- [ ] Normal pin-blocking during an active pinch is preserved
- [ ] Existing tests pass; cancellation scenario is documented (test or comment)
