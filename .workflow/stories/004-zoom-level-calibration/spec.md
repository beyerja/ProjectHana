# Story 004: Zoom Level Calibration

## Goal
Widen the map region shown during the quiz so that at least 10 neighbouring countries are visible, and the target country can appear anywhere in the visible area (not always at center), forcing the user to genuinely know the country's location.

## Acceptance Criteria
- [ ] The `refreshAnnotations` / `region(for:)` logic is extracted into a shared helper (no duplication between `MapQuizSession` and `MapLearningSession`).
- [ ] At least 10 annotation countries are shown per question (nearest neighbours by geographic distance within the same continent, or globally if fewer than 10 continental neighbours exist).
- [ ] The map region center is offset from the target country's coordinates by a random amount (within the visible span) so the target country can appear near the center or near the edges.
- [ ] The minimum span is large enough that 10+ countries fit within the viewport; the current fixed minimum of 12 degrees is retained as a floor but the neighbour count drives the span.
- [ ] Unit tests verify: at least 10 annotation countries returned, center offset applied, shared helper used by both session types.
- [ ] Existing tests continue to pass.
