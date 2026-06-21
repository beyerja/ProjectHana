# Log — Story 005: One-time migration legacy → mapQuiz

## Tasks
- [x] 001: Add a per-quiz-mode migration step to `ProgressMigrator` with its own version flag `progress.perQuizModeMigration.v1.done`, run from `migrateIfNeeded` AFTER the existing per-language stamp (so legacy rows already carry the active language) and guarded independently (idempotent; coexists with the per-language flag).
- [x] 002: Stamp every empty-`quizMode` `ReviewCard` with `mapQuiz` (filter empty-quizMode in Swift, mirroring the empty-language approach). Do NOT stamp `DailyProgressSnapshot` rows — leave them at `quizMode == ""` (they remain the mode-aggregated rollup the default Progress chart reads). Only empty-quizMode cards are touched → re-run is a no-op.
- [x] 003: Copy each legacy per-`(language, category)` active set (`legacyPerLanguageActiveSetKey`) into the `mapQuiz` per-mode active-set key (`activeSetKey(language:mode:.mapQuiz:category:)`), only when the target is absent; remove the legacy per-language key. Other modes' active sets stay absent (empty/fresh).
- [x] 004: Confirm ordering at app startup: migration runs before `CardStoreProvider.seedAllModes()` (it already does in `AppRootView.rebuildStores`). The mapQuiz store's `seedIfNeeded` then sees the migrated cards and only seeds genuinely-missing facts.
- [x] 005: Tests: legacy cards stamped mapQuiz; snapshots stay aggregate ""; legacy per-language active set copied to mapQuiz key; idempotent re-run; per-language migration still idempotent (regression); fresh install unaffected. `just generate`/`lint`/`test` green.
