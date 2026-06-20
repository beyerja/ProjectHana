# Story 001 — Add a language dimension to the persisted progress models

## Goal
Give the two SwiftData `@Model`s that hold progress — `ReviewCard` and `DailyProgressSnapshot` —
a `language` attribute, plus a lightweight SwiftData migration so existing on-disk stores upgrade
in place (no wipe) with the new column defaulted to empty. This is the abstraction-first story:
later stores/UI scope by this column. It ships compiling and behavior-neutral on its own.

## Design
- Add `var language: String = ""` to `ReviewCard` (and to its `init`, defaulted to `""`).
- Add `var language: String = ""` to `DailyProgressSnapshot` (and to its `init`, defaulted to `""`).
  - `""` is the "unassigned / legacy global" sentinel; Story 005 migrates these to the active locale.
  - Keep CloudKit-safety: defaulted, non-optional-with-default is fine; NO `@Attribute(.unique)`.
- Provide a SwiftData migration plan (`SchemaMigrationPlan` + `VersionedSchema`s, or rely on
  SwiftData lightweight migration) so adding a defaulted column does NOT trip the
  `makeModelContainer()` catch-and-wipe path. Wire the plan into
  `SyncCoordinator.makeModelContainer()` via `ModelContainer(for:migrationPlan:configurations:)`.
  Verify the wipe-on-failure fallback still exists for genuinely incompatible stores.

## Acceptance Criteria
1. `ReviewCard` and `DailyProgressSnapshot` each have a defaulted `language: String` stored property,
   threaded through their initializers.
2. No `@Attribute(.unique)` is introduced; all stored properties keep model-level defaults
   (CloudKit-sync-ready preserved).
3. A migration path exists such that an existing on-disk store gains the new column WITHOUT being
   wiped (lightweight migration), and the catch-all wipe fallback remains for incompatible schemas.
4. The project builds and the existing test suite passes unchanged (no behavior change yet:
   `language` defaults to `""` everywhere).
