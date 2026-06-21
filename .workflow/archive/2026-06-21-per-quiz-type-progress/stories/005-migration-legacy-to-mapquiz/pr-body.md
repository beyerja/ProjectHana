## Goal

On upgrade, attribute all pre-existing progress (which was effectively the Map Tab Quiz) to the
`mapQuiz` mode; the other three modes start empty/fresh. One-time, idempotent, coexists with the
existing per-language migration. (Story 5 of 6.)

## Changes

- **Split `ProgressMigrator.migrateIfNeeded`** into the existing per-language step + a new
  per-quiz-mode step with its own flag (`progress.perQuizModeMigration.v1.done`). The per-mode step
  runs **after** the per-language stamp (legacy rows already carry the active language) and is
  independently idempotent.
- **Stamp every empty-`quizMode` `ReviewCard` with `mapQuiz`.** **`DailyProgressSnapshot` rows are left
  at `quizMode == ""`** — they are the mode-aggregated rollup the default Progress chart reads;
  stamping them mapQuiz would empty the default history.
- **Copy the legacy per-language active set into the `mapQuiz` per-mode key** (only when absent) and
  remove the legacy per-language key; other modes' active sets stay empty.
- Runs before `CardStoreProvider.seedAllModes()` (already ordered in `AppRootView`), so the mapQuiz
  store inherits the migrated cards rather than re-seeding fresh ones.

## Test plan

- [x] `just lint` clean
- [x] `just test` — TEST SUCCEEDED
- [x] New `PerQuizModeMigratorTests`: legacy cards → mapQuiz; snapshots stay aggregate (`""`); legacy
      per-language active set → mapQuiz key (other modes empty); idempotent re-run (a card later graded
      in another mode is not re-stamped); fresh install no-op.
- [x] Updated `ProgressMigratorTests.testMigratesLegacyActiveSet…` for the new end-state (the legacy
      active set now lands in the `mapQuiz` key); the per-language migration remains idempotent.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
