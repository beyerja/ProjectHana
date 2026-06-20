# Story 001 — `just install` backs up progress before replacing the app

## Goal
Add a recipe-level safety net so running `just install` can never be the cause of progress loss:
snapshot the user's progress data and preferences to a timestamped backup before the app bundle is
replaced, verify the live store survives the install, and cap backups.

This story lands in the PRIMARY checkout (justfile is build/workflow tooling).

## Scope
Edit the `install` recipe in `justfile` (and only the recipe / closely-related helper).

## Behavior
1. BEFORE `pkill`/`rm -rf`/`cp`, copy these into
   `~/Library/Application Support/Hanahuac-backups/<UTC-timestamp>/` (best-effort, skip missing):
   - `~/Library/Application Support/default.store`
   - `~/Library/Application Support/default.store-wal`
   - `~/Library/Application Support/default.store-shm`
   - `~/Library/Preferences/maccatalyst.com.hanahuac.app.plist`
2. Prune the backups dir to the 10 most recent timestamped subdirectories.
3. Proceed with the existing install (build dep, pkill, rm, cp, open).
4. AFTER install, verify `~/Library/Application Support/default.store` still exists. If it is missing,
   print a loud warning naming the most recent backup dir for manual restore (do not auto-restore).
5. A fresh install with no pre-existing store must NOT fail the recipe.

## Acceptance criteria
- Running `just install` creates a new timestamped dir under
  `~/Library/Application Support/Hanahuac-backups/` containing whichever of the four source files exist.
- Only the 10 newest backup dirs are retained; older ones are pruned.
- The recipe still builds, kills, replaces, and launches the app exactly as before.
- The recipe exits 0 on a machine with no existing store (no false failure).
- `just lint` (in particular shellcheck on any shell, and the recipe body) passes.
- Backup logic runs BEFORE the destructive `rm -rf /Applications/Hanahuac.app` / `cp` step.
