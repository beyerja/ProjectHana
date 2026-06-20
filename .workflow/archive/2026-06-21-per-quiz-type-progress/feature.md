# Feature: Per-quiz-type progress tracking

## Goal
Track learning progress **separately per quiz type** within a category, instead of all quiz modes of
a category sharing the same underlying spaced-repetition state. A user's progress in the Map Tab Quiz
must be independent from their progress in the Multiple Choice quiz (and the other modes) for the same
fact — so practicing one mode does not advance another. This adds `quizMode` as an orthogonal second
dimension to the per-language dimension that already exists.

## Background (current state)
The progress unit is `ReviewCard` (SwiftData `@Model`), today keyed by `(factID, language)`. All quiz
views load `ReviewCard`s through a single language-scoped `CardStore` and mutate the SM-2 fields in
place — so **all quiz modes currently SHARE the same card per fact**, meaning progress bleeds across
modes within a category.

- Quiz modes are enumerated in `HomeQuizMode` (`Hanahuac/Views/Home/QuizRoute.swift`):
  `mapQuiz`, `multipleChoice`, `typeCapital` (Countries-only), `nameFeature`.
  Views include `CapitalQuizView`, `NameFeatureQuizView`, plus the map-tab and multiple-choice views.
- The per-language dimension already exists and is the pattern to mirror: a defaulted column on the
  `@Model` (`language`), stores scoped by it (`CardStore`, `ProgressStatsStore`), key-value
  namespacing (`StreakTracker`, `ActiveSetStore`), a versioned `SchemaV2`, and a one-time
  `ProgressMigrator` stamping legacy rows.
- Progress is CloudKit-sync-ready (no `@Attribute(.unique)`, optional/defaulted fields, app-level
  dedup).

## Scope (clarified — FINAL)
Add `quizMode` as an orthogonal dimension alongside the existing `language` dimension. Final card
identity becomes `(factID, language, quizMode)`.

1. **All four modes fully independent.** A fact can have up to 4 separate `ReviewCard`s, one per mode
   (`mapQuiz`, `multipleChoice`, `typeCapital`, `nameFeature`). No sharing of SM-2 state between modes.
2. **Model the new dimension exactly like `language`.** Add a defaulted `quizMode: String = ""` column
   to `ReviewCard`; card identity becomes `(factID, language, quizMode)`; scope `CardStore` by
   `(language, quizMode)` — a CardStore per active mode. Additive, CloudKit-safe, lightweight-migratable.
   Bump head schema (e.g. `SchemaV3`).
3. **Migration.** All existing/legacy progress was effectively the Map Tab Quiz — so stamp ALL legacy
   progress onto the `mapQuiz` mode. The other three modes (`multipleChoice`, `typeCapital`,
   `nameFeature`) start empty/fresh. One-time, idempotent migrator, same pattern as the per-language
   `ProgressMigrator`. Must coexist cleanly with the existing per-language migration (legacy rows
   already stamped with the active language get additionally stamped with `mapQuiz`).
4. **Streak — SHARED across modes, per-language (unchanged dimension).** Keep `StreakTracker`
   per-language and shared across modes: a review in ANY mode keeps the day-streak. Do NOT split the
   streak per mode.
5. **Active set — PER MODE.** Namespace `ActiveSetStore` by `(language, mode, category)` so each mode
   independently tracks what's "new"/in-progress.
6. **Daily stats / Progress screen — aggregated by default + per-mode breakdown.** Show stats
   AGGREGATED across modes by default (current behavior — totals per `(day, language)`), AND add an
   option/toggle to view the per-mode breakdown (individual mode totals). Record enough per-mode data
   to support the breakdown.
7. **`typeCapital` stays Countries-only.** A mode simply has no cards for categories it doesn't serve.
   Unchanged.

## Behavior requirements
- **Independent SM-2 tracks per mode.** Grading a fact in the Map Tab Quiz must not change that fact's
  card in Multiple Choice (or any other mode), and vice versa. Each `(factID, language, quizMode)` is
  an independent card.
- **Migration.** On upgrade, stamp ALL pre-existing progress (already attributed to the active
  language) onto `quizMode == "mapQuiz"`. The other three modes start empty. Migration runs once, is
  idempotent, and must not lose or duplicate existing progress.
- **Streak preserved.** A graded review in any mode advances the per-language streak exactly as today.
- **Active set isolation.** Each mode's active set is independent; advancing the Multiple Choice active
  set does not affect the Map Tab Quiz active set for the same `(language, category)`.
- **Stats default unchanged + opt-in breakdown.** The Progress screen's default totals remain
  aggregated across modes (matching today's numbers after migration), with a toggle revealing per-mode
  totals.
- **CloudKit sync.** Preserve sync readiness. Dedup keys on `(factID, language, quizMode)`. No
  `@Attribute(.unique)`; optional/defaulted fields.

## Acceptance criteria
1. `ReviewCard` carries a defaulted `quizMode` column; card identity and dedup key on
   `(factID, language, quizMode)`; two modes may hold a card for the same `(factID, language)` without
   collision.
2. Each quiz mode loads/saves SM-2 state through a `CardStore` scoped by `(language, quizMode)`;
   grading a fact in one mode leaves the same fact's cards in the other modes untouched (verified by
   tests).
3. A one-time, idempotent migration stamps all pre-existing progress onto `mapQuiz`; the other three
   modes start empty; re-running it does not duplicate or drop data (verified by tests).
4. `ActiveSetStore` is namespaced by `(language, mode, category)`; each mode's active set advances
   independently (verified by tests).
5. `StreakTracker` remains per-language and shared across modes; a review in any mode advances the
   single per-language streak (verified by tests).
6. The Progress screen defaults to mode-aggregated totals (matching pre-feature numbers after
   migration) and offers a per-mode breakdown toggle; per-mode data is recorded to back the breakdown.
7. `typeCapital` remains Countries-only — no cards are created for categories it does not serve.
8. The head schema is bumped (e.g. `SchemaV3`) with a lightweight, CloudKit-safe migration; sync
   readiness is preserved (no `@Attribute(.unique)`, optional/defaulted fields, app-level dedup by
   `(factID, language, quizMode)`).
9. Build passes and the full test suite (including new per-quiz-mode tests) is green in CI.

## Non-goals
- Splitting the streak per mode (explicitly shared across modes).
- Changing which categories a mode serves (`typeCapital` stays Countries-only).
- Per-mode fact-set divergence beyond what `(factID, language, quizMode)` keying already permits.
