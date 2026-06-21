## Goal

Record daily progress **both per quiz mode and as a mode-aggregated rollup**, and fix the follow-up
from #125 where the aggregate daily snapshot was being overwritten with only the last-graded mode's
counts. The Progress screen's default totals stay mode-aggregated and unchanged; per-mode data is now
captured to back the breakdown (Story 6). (Story 3 of 6.)

## Changes

- **`ProgressStatsStore` is now `(day, language, quizMode)`-keyed:** `snapshots(forQuizMode:)` /
  `snapshots(forQuizMode:since:)` accessors; `deduplicate` / `canonicalSnapshot` scoped per
  `(day, quizMode)` so the aggregate `""` row and a per-mode row for the same day are not duplicates.
  `allSnapshots` / `snapshots(since:)` still return the aggregate rows → **default Progress view
  unchanged**.
- **New `recordSnapshot(allCards:modeCards:mode:streak:)`** upserts BOTH the aggregate row (from the
  cross-mode union) AND the per-mode row. The back-compat `recordSnapshot(cards:streak:)` still writes
  the aggregate.
- **All 7 quiz-view call sites** now pass `cardStoreProvider.allCards` (aggregate) + `cardStore.allCards`
  (this mode) + the mode token — so the aggregate reflects every mode (fixing the #125 under-count) and
  per-mode data is recorded.
- **Streak untouched** — still per-language and shared across modes.

## Test plan

- [x] `just lint` clean
- [x] `just test` — TEST SUCCEEDED
- [x] New `PerModeSnapshotTests`: aggregate reflects all modes (not just the last graded), per-mode
      rows independent, aggregate + per-mode coexist for a day (not dupes), idempotent per (day, mode),
      and a shared-streak regression guard (a review in any mode advances the single per-language
      streak).
- [x] Existing snapshot/stats tests unchanged and green (the aggregate `""` path is the back-compat
      default).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
