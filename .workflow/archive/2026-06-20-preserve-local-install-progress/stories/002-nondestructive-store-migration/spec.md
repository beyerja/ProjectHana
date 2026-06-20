# Story 002 — Non-destructive SwiftData store: migration plan + backup-before-wipe

## Goal
Stop the app from silently destroying the user's progress on upgrade. Two app-code changes:
1. Add an explicit versioned SwiftData schema + `SchemaMigrationPlan` so the current models open an
   existing on-disk store across (at least lightweight/additive) schema changes instead of throwing.
2. Make the wipe-on-failure path in `SyncCoordinator.makeModelContainer()` non-destructive: copy the
   existing store to a timestamped backup BEFORE any deletion, and only delete as a genuine last
   resort (when even a guaranteed-local container cannot open). Apply a 10-backup retention cap.

This story lands in a WORKTREE (Swift app source).

## Affected source
- `Hanahuac/Sync/SyncCoordinator.swift` (`makeModelContainer()` and helpers).
- New schema-versioning type(s) for `ReviewCard` + `DailyProgressSnapshot` (a `VersionedSchema` /
  `SchemaMigrationPlan`), e.g. under `Hanahuac/Models/` or `Hanahuac/Sync/`.
- Tests under the existing test target.

## Behavior
- The `ModelContainer` is built from a versioned schema with a migration plan. A normal additive
  schema change opens the existing store with data intact (no wipe).
- If `ModelContainer(...)` still throws, before deleting `default.store{,-wal,-shm}`:
  - Copy the existing files to
    `~/Library/Application Support/Hanahuac-backups/<UTC-timestamp>-autorecover/` (best-effort).
  - Prune to the 10 most recent backup dirs (shared root with story 001).
  - Then attempt the guaranteed-local container. Only if THAT also throws may the store be deleted,
    and only then as the documented last resort.
- The backup root + retention cap (10) match story 001's:
  `~/Library/Application Support/Hanahuac-backups/`.

## Acceptance criteria
- A versioned schema + `SchemaMigrationPlan` is wired into `makeModelContainer()`.
- `makeModelContainer()` never deletes the store without first having attempted to back it up; the
  delete only happens as a last resort after a non-destructive recovery attempt.
- Backups obey the 10-dir retention cap and live under the shared backup root.
- A unit test covers the backup-before-wipe logic (e.g. injecting/observing that an existing store is
  copied to the backup root before any removal). Pure backup/retention helpers are testable in
  isolation.
- `just test`, `just lint`, and `just build-mac` all pass.

## Notes
- Default (flag-OFF) local-only behavior must remain byte-compatible aside from the new migration
  plan; the `#if CLOUDKIT_SYNC` branch stays gated and unchanged.
- Keep the backup-path/retention constants shared/DRY within the app code.
