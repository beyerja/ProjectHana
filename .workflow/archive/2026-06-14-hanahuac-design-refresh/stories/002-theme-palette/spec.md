# 002 — Central Theme / pastel palette

## Goal
Introduce a single reusable Theme/Palette abstraction defining the warm pastel light-mode color
system, wire it into `AccentColor`, and replace every hardcoded inline color across the app with a
palette reference. Light mode only — no dark-mode color sets.

## Scope / Files
- New `ProjectHana/Theme/Theme.swift` (or `Palette.swift`) exposing a `Palette` / `Theme` with named
  semantic colors. Define colors once (hex initializer or asset colorsets) and expose:
  - `canvas` (~#FBF7F0), `surface` (~#F4EEE4 / white), `primaryAccent` (~#E8A398),
    `secondaryAccent` (~#9FC9B6), category pastels (countries ~#A8C0E8, rivers ~#9ED7DE,
    mountains ~#C9A9A6, seas ~#8FCFC9), `textPrimary` (~#3A332E), `textSecondary` (~#8A8077),
    state pills (new=pastel green, pending=pastel periwinkle).
  - Refine any combo failing reasonable WCAG contrast (text on canvas/surface).
- Populate `AccentColor.colorset/Contents.json` with the primary accent (light appearance only).
- Replace hardcoded colors in: `Views/Home/QuizRoute.swift`, `Views/Home/PilePickerView.swift`,
  `Views/Home/HomeView.swift`, `Views/Progress/StatsView.swift`, `Views/Quiz/LearningQuizView.swift`,
  `Views/Quiz/MultipleChoice/MultipleChoiceQuizView.swift`, `Views/Quiz/MapQuiz/*` (QuizSummaryView,
  MapQuizView, MapQuizSession, MapLearningQuizView), `Views/Quiz/TextQuiz/CapitalQuizView.swift`,
  and any others using `.blue/.cyan/.brown/.teal/.quaternary/Color.secondary.opacity` ad hoc.
- Category color mapping (Countries/Rivers/Mountains/Seas) should come from the palette.
- `.quaternary` card backgrounds → palette `surface` with subtle depth (soft shadow / hairline border).

## Acceptance Criteria
- [ ] A central Theme/Palette type exists; colors defined once.
- [ ] `grep` for ad-hoc `.blue/.cyan/.brown/.teal/.quaternary` in `Views/` returns no view-styling
      hits (correctness-only semantic colors like `.green`/`.red` for right/wrong answers may stay
      if intentional, but prefer palette equivalents).
- [ ] AccentColor colorset carries the primary accent; app tint reflects it.
- [ ] Pastel palette visibly applied across home, quizzes, stats, settings — light mode only.
- [ ] No dark-mode color variants added.
- [ ] Text/background combos meet reasonable contrast.
- [ ] Builds iOS + macOS; tests pass.

## Notes
- Visual/identity only — do not alter quiz correctness logic; only the colors it renders with.
- Depends on 001 (uses new app/source naming) but is otherwise independent.
