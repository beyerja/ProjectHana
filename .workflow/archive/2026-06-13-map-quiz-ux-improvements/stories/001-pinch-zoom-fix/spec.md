# Story 001: Pinch-to-Zoom Fix

## Goal
Prevent the map's two-finger pinch-to-zoom gesture from being misinterpreted as a tap on whichever country pin the fingers happen to be positioned over.

## Acceptance Criteria
- [ ] Performing a two-finger pinch over a country pin does not trigger `handleTap` for that pin.
- [ ] Single-finger tap on a country pin still correctly triggers `handleTap`.
- [ ] The fix applies to both `MapQuizView` and `MapLearningQuizView`.
- [ ] Existing unit tests continue to pass; no regressions in quiz logic.
