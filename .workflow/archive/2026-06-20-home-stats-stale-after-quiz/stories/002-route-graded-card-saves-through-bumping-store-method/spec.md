# 002 — Route quiz graded-card saves through a bumping store method

Branch: `story/home-stats-stale-after-quiz/graded-card-save-bumps-signal`

## Title
Ensure every quiz grading / card-state save routes through a `CardStore` method that bumps the
revision signal, so the home pills update even if a session saves the `ModelContext` directly.

## Goal
Story 001 bumps the revision on `recordSnapshot`, and every quiz completion path already calls
`recordSnapshot`, which covers the common case. This story removes the remaining fragility: any quiz
session (`MultipleChoiceSession`, `MapQuizSession`, `TextQuizSession`, and the map/learning sessions)
that mutates a `ReviewCard` and saves directly on the shared `ModelContext` — without going through a
revision-bumping store method — is a latent staleness bug if a future path skips `recordSnapshot`.
Make the graded-review persistence explicitly route through a `CardStore` entry point that bumps the
signal, so the home count pills are correct regardless of whether `recordSnapshot` is called.

## Scope
- Audit each quiz session/view that mutates `ReviewCard` SR state during grading:
  `MultipleChoiceSession`, `MapQuizSession`, `MapLearningSession`, `TextQuizSession`,
  `MultipleChoiceQuizView`, `MapQuizView`, `CapitalQuizView`, `NameFeatureQuizView`, and the learning
  variants. Identify where the card mutation is persisted (direct `modelContext.save()` vs a store
  method).
- Add a `CardStore` entry point for persisting a graded/reviewed card (e.g.
  `func recordReview(_ card: ReviewCard)` or a generic `func persistCardChanges()` that saves and
  bumps the revision), depending on what the audit shows the sessions need. Reuse story 001's
  `markChanged()` helper so the revision bump stays in one place.
- Update the graded-review save paths to call that store method instead of saving the context
  directly, so each card mutation bumps `CardStore.revision`.
- Keep behavior identical (same SR computations, same persisted fields); only the save routing
  changes. No change to snapshot recording.
- Keep changes language-scoped and side-effect-free with respect to other languages.

## Out of scope
- The revision property and HomeView/StatsView wiring (delivered by story 001 — this story depends on
  it).
- CloudKit sync, dedup logic, migration, streak-key storage.

## Acceptance Criteria
1. Every quiz grading path that mutates and persists a `ReviewCard` routes its save through a
   `CardStore` method that bumps the revision signal (no graded-card mutation persists via a bare
   `modelContext.save()` that bypasses the bump).
2. After completing or partially exiting a quiz of any type (MultipleChoice, MapQuiz, TextQuiz —
   Capital / NameFeature) in either the "new" (learning) or "pending" (review) pile, across countries
   / rivers / mountains / seas, the home pills and Progress screen reflect the new state immediately
   with no relaunch — even if the `recordSnapshot` call were absent.
3. SR grading behavior is unchanged (the same card fields are computed and persisted as before).
4. Automated tests cover the new `CardStore` graded-review entry point: calling it bumps the revision
   and persists the card's updated state. Tests go in `HanahuacTests/CardStoreTests.swift`.
5. The fix holds on a clean store/build (CI), not only on a warm local simulator.
6. `just lint` and `just test` pass.

## Notes
- If the audit finds that all graded saves already flow through a store method (i.e. sessions never
  touch `modelContext` directly), this story reduces to: confirm with a test that the graded-review
  store method bumps the revision, and add the explicit entry point only if one is missing. Keep the
  change minimal — do not refactor session logic beyond the save routing.
- Depends on story 001 (the `revision` property and `markChanged()` helper must exist first).
