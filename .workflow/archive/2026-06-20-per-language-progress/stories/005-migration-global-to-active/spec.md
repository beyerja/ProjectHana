# Story 005 — One-time migration of existing global progress to the active language

## Goal
On upgrade, attribute ALL pre-existing global progress to the language that is active at upgrade
time; every other language starts empty. The migration is one-time and idempotent.

## Design
Two classes of pre-existing data to migrate, both keyed today with no language:

1. **SwiftData rows** (`ReviewCard`, `DailyProgressSnapshot`): after Story 001's column add, legacy
   rows carry `language == ""`. A one-time app-level migration stamps every row with
   `language == ""` to `LanguageManager.shared.current.rawValue`, then saves. Idempotent: it only
   touches rows whose `language` is empty, so a second run is a no-op. Guard with a persisted
   "migration done" flag (e.g. a `PreferenceStore`/UserDefaults version key) AND the empty-language
   check, so re-running never duplicates or drops data.

2. **Key-value progress** (streak + active set from Story 004): legacy keys are the un-namespaced
   originals (`streak_count`, `streak_lastReviewDate`, `activeSet.<category>`). Migrate by copying
   each legacy value into the active-language-namespaced key if the namespaced key is absent, then
   (optionally) removing the legacy key. Idempotent via presence checks / the version flag.

- Run the migration once at startup, before stores seed, so seeding doesn't create empty-language
  duplicates ahead of the stamp. Order in `HanahuacApp.AppRootView.onAppear`:
  migrate → construct language-scoped stores → seedIfNeeded.
- After migration, fresh installs (no legacy data) are unaffected: there is nothing to stamp and the
  active language seeds normally.

## Acceptance Criteria
1. A one-time migration assigns all pre-existing global `ReviewCard` and `DailyProgressSnapshot`
   rows (and legacy streak + active-set key-value data) to the active language at upgrade.
2. Migration is idempotent: running it again does not duplicate, drop, or re-stamp already-migrated
   data (verified by a test that runs it twice).
3. Other languages start empty after migration.
4. Fresh installs (no legacy data) behave correctly — nothing to migrate, normal seeding.
5. Build passes; migration tests are green; existing tests stay green.
