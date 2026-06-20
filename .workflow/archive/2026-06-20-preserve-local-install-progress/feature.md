# Feature: Preserve local-install progress across app upgrades

## Slug
`preserve-local-install-progress`

## Problem
Installing a new local build via `just install` has, in the past, wiped the user's accumulated
progress (review cards, daily-progress snapshots) and/or preferences. A diagnostic confirmed the
current `just install` recipe does **not** delete user data on disk — the loss came from the app
itself: `SyncCoordinator.makeModelContainer()` silently **deletes and reseeds** `default.store`
whenever the SwiftData `ModelContainer` fails to open. That happens on any schema change shipped
without a migration plan (and historically also on the `com.projecthana.app` → `com.hanahuac.app`
bundle/data-domain change). The result is silent, unrecoverable progress loss on upgrade.

## Where progress lives (non-sandboxed Mac Catalyst app)
1. Learning progress (review cards + daily-progress snapshots) → SwiftData store at
   `~/Library/Application Support/default.store` plus `-wal` / `-shm` sidecars.
2. Preferences (sync opt-in, active set) → `~/Library/Preferences/maccatalyst.com.hanahuac.app.plist`.

## Goal
Make local upgrades non-destructive to all progress (learning data **and** preferences), via two
complementary layers:

### (a) Recipe-level safety net — PRIMARY checkout (justfile)
Before installing, `just install` snapshots the user's progress to a timestamped backup, then
restores nothing automatically but verifies the live data is still present after install (and the
backup exists as a recovery point). Concretely:
- Back up `~/Library/Application Support/default.store{,-wal,-shm}` and the preferences plist
  `~/Library/Preferences/maccatalyst.com.hanahuac.app.plist` into a timestamped directory under
  `~/Library/Application Support/Hanahuac-backups/<UTC-timestamp>/` BEFORE killing/replacing the app.
- After install completes, verify the live `default.store` still exists (warn loudly if it does not,
  pointing the user at the most recent backup for manual restore).
- Backups are best-effort: a missing store on a first-ever install is not an error.
- **Retention cap: keep the most recent 10 backup directories; prune older ones.** (Chosen default;
  documented here.)
- This recipe change must land in the PRIMARY checkout (build/workflow tooling), NOT a worktree.

### (b) App-code fix — WORKTREE (Swift source)
Make the app open existing stores instead of destroying them:
- Add an explicit SwiftData `SchemaMigrationPlan` / versioned schema so the current models open an
  existing on-disk store across (at minimum lightweight) schema changes instead of throwing.
- Make the wipe-on-failure path in `SyncCoordinator.makeModelContainer()` **non-destructive**: before
  any deletion, copy the existing `default.store{,-wal,-shm}` to a timestamped backup under
  `~/Library/Application Support/Hanahuac-backups/<UTC-timestamp>-autorecover/`. Only wipe as a true
  last resort (when even a guaranteed-local container cannot be opened), and never silently — the
  backup is the recovery point. Apply the same 10-backup retention cap.

## Acceptance criteria
1. `just install` writes a timestamped backup of `default.store{,-wal,-shm}` + the preferences plist
   under `~/Library/Application Support/Hanahuac-backups/` before replacing the app bundle, and prunes
   to the 10 most recent backups. Missing source files (fresh install) do not fail the recipe.
2. After `just install`, the live SwiftData store is unchanged (same file, progress intact); the
   recipe verifies its presence and warns if absent.
3. The app defines a versioned SwiftData schema + migration plan so a normal (additive/lightweight)
   schema change opens the existing store with progress intact rather than triggering the wipe path.
4. `SyncCoordinator.makeModelContainer()` never deletes the store without first copying it to a
   timestamped backup, and only deletes as a genuine last resort. The autorecover backups also obey
   the 10-backup retention cap.
5. All project checks pass: `just test`, `just lint`, and `just build-mac`.

## Out of scope
- iCloud/CloudKit sync behavior (gated behind `#if CLOUDKIT_SYNC`, unchanged).
- Automatic restore of a backup into the live store (backups are a manual recovery point only).
- Migrating the historical `com.projecthana.app` plist (one-time legacy domain; not re-introduced).

## Notes
- Backup root: `~/Library/Application Support/Hanahuac-backups/`.
- Retention cap: 10 most recent backup directories (recipe and app share the same cap + root).
