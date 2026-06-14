# 005 — Redesigned home landing

## Goal
Restyle the home landing into a branded, polished experience using the new palette and logo mark,
while keeping all existing navigation, data flow, and quiz routing intact.

## Scope / Files
- `Views/Home/HomeView.swift` (primary), `Views/Home/PilePickerView.swift`,
  `Views/Home/QuizRoute.swift`, `ContentView.swift` as needed; new component(s) under
  `Views/Components/` if helpful.
- Branded header area: `LogoMark` (004) + "Hanahuac" wordmark on the pastel canvas, replacing the
  plain large nav title.
- Restyle category sections + quiz-mode rows: palette colors, improved card depth (soft shadow /
  hairline border), rounded friendly typography (e.g. `.rounded` design), consistent SF Symbol
  iconography per category.
- Tasteful micro-animations/transitions: subtle appearance + button-press feedback (not distracting).
- Polish empty/disabled states (e.g. no cards due) so they look intentional, not broken.

## Acceptance Criteria
- [ ] Home shows a branded header (logo mark + "Hanahuac" wordmark) on the pastel canvas.
- [ ] Category sections and quiz rows are restyled with palette, card depth, rounded typography,
      consistent iconography.
- [ ] Subtle micro-animations on appearance and button press.
- [ ] Empty/disabled states look intentional.
- [ ] All existing navigation and quiz flows still work (routes unchanged).
- [ ] Builds iOS + macOS; tests pass; verified visually in the simulator.

## Notes
- Visual only — do not change navigation structure, routing, or quiz behavior.
- Depends on 001 (name), 002 (palette), 004 (logo mark).
