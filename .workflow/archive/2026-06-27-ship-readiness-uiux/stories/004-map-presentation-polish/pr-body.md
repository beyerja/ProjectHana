## Goal

Polish the quiz-map presentation (AC5) without changing its core style. The satellite base
(`.mapStyle(.imagery)`) is the deliberate, correct answer to the place-name-label problem — a
labeled MapKit style would reveal answers, and iOS MapKit offers no fine label suppression. This
pass improves only the surrounding presentation and makes it consistent across the map-based
quizzes.

## Changes

- Unified the overlay prompt card style across `MapQuizView`, `MapLearningQuizView`, and
  `NameFeatureQuizView` so the prompt presentation is consistent across all three map-based quizzes.
- Tidied and cleared the bottom **Apple Maps / Legal** attribution placement so it no longer
  collides with the overlay card and reads cleanly on every quiz screen.
- Kept all new/adjusted user-visible strings localized across every locale.

## Hard constraints honored

- Kept `.mapStyle(.imagery(elevation: .flat))` satellite base — no switch to a labeled map style.
- **No place-name labels** introduced anywhere on the quiz map (hard correctness constraint).
- **No** full vector / non-MapKit quiz-map redesign — the satellite base stays for this pass.

## Live UI verification (AC9)

Verified LIVE via `just ui-walkthrough` against the booted iPhone 17 / iOS 26.5 simulator —
inspecting both screenshots and accessibility dumps across the Map quiz and the Name-Feature quiz.
BEFORE/AFTER evidence (screenshots + accessibility dumps) captured at:

- `.workflow/ui-walkthrough/before/`
- `.workflow/ui-walkthrough/after/`

Screenshot inspection confirms no answer-revealing place-name labels on the map and that the
overlay card + attribution are tidy and consistent across both quizzes.

## Test plan

- [x] `just lint`
- [x] `just test`
- [x] `just l10n-check`
- [x] Live `just ui-walkthrough` — BEFORE/AFTER screenshots + a11y dumps reviewed, no place-name labels

🤖 Generated with [Claude Code](https://claude.com/claude-code)
