# Story 005 — One-time migration: attribute all legacy progress to the Map Tab Quiz mode

## Goal
On upgrade, all pre-existing progress (which was effectively the Map Tab Quiz) is stamped onto the
`mapQuiz` mode. The other three modes (`multipleChoice`, `typeCapital`, `nameFeature`) start empty.
The migration is one-time, idempotent, and coexists cleanly with the existing per-language migration.

## Background
`ProgressMigrator.migrateIfNeeded(context:activeLanguage:defaults:)` already runs once at startup
(before seeding) to stamp empty-`language` rows with the active locale and copy legacy key-value
streak/active-set data into the language-namespaced keys, guarded by a `versionKey` flag plus
per-step presence checks. Stories 001–004 added the `quizMode` column, mode-scoped CardStore/snapshots,
and the per-`(language, mode, category)` active-set key. Legacy rows after Stories 001–004 carry a
real `language` (from the prior migration) but an empty `quizMode`.

## Scope
- Extend the one-time migrator (new version flag, e.g. `progress.perQuizModeMigration.v1.done`, OR a
  bumped combined flag — but DO NOT regress the existing per-language migration's idempotency) to:
  - Stamp every `ReviewCard` and `DailyProgressSnapshot` whose `quizMode` is empty with the `mapQuiz`
    token. (Empty-`quizMode` filter done in Swift, matching the existing empty-`language` approach.)
    Only empty-`quizMode` rows are touched, so a re-run is a no-op.
  - Copy each legacy per-`(language, category)` active set (the Story-004 "legacy" key) into the
    `mapQuiz` per-mode active-set key, only when the target key is absent; remove the legacy key. The
    other modes' active-set keys are left absent (empty/fresh).
  - Leave `StreakTracker` data alone — streak stays per-language and shared across modes; nothing to
    re-key per mode.
- Ordering: run BEFORE the provider seeds per-mode stores, so seeding never creates empty-`quizMode`
  rows ahead of the stamp, and so the `mapQuiz` store inherits the migrated cards rather than
  re-seeding fresh ones. Coexist with the existing per-language stamp (a legacy row gets both its
  active language and `mapQuiz`).
- **IMPORTANT — snapshots are NOT cards (carried from Story 003 review):** stamp only legacy
  `ReviewCard` rows with `mapQuiz`. Do NOT stamp legacy `DailyProgressSnapshot` rows with `mapQuiz`:
  after Story 003 the empty-`quizMode` snapshot IS the **mode-aggregated** rollup that the Progress
  screen's default chart reads, and legacy daily snapshots already represent the all-modes total for
  those past days. Stamping them `mapQuiz` would empty the default aggregate history. So: leave legacy
  snapshots at `quizMode == ""` (they remain the aggregate). The pre-Story-001 migration already
  stamped them with the active `language`; nothing further is needed for snapshots here. (Optionally
  the migrator MAY also write a `mapQuiz` per-mode copy of each legacy snapshot so the per-mode
  breakdown shows history for the Map Tab Quiz — but the aggregate `""` rows must be preserved either
  way.)
- Fresh installs (no legacy data) are unaffected — nothing to stamp or copy.

## Acceptance Criteria
- [ ] A one-time, idempotent migration stamps all empty-`quizMode` `ReviewCard` rows with `mapQuiz`;
      the other three modes start with no cards. Legacy `DailyProgressSnapshot` rows are LEFT at
      `quizMode == ""` (they remain the mode-aggregated rollup the default Progress chart reads).
- [ ] Legacy per-`(language, category)` active sets are copied into the `mapQuiz` per-mode active-set
      key (only when absent); other modes' active sets start empty.
- [ ] Re-running the migration does not duplicate, drop, or re-stamp already-migrated data (verified by
      a test running it twice).
- [ ] The existing per-language migration still works and remains idempotent (regression test green).
- [ ] After migration, the Map Tab Quiz shows exactly the user's prior progress; the other modes start
      fresh — verified by a test.
- [ ] Migration runs before per-mode seeding so no empty-`quizMode` rows are seeded ahead of the stamp.
- [ ] `just build` and `just test` green, including new migration tests.
