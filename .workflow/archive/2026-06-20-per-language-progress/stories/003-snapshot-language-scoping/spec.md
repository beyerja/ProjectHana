# Story 003 — Scope daily progress snapshots per language

## Goal
Make `ProgressStatsStore` operate per language: daily snapshots are recorded, fetched, and
deduplicated within the active language, so each language has its own day-by-day stats history.
Depends on Story 001's `DailyProgressSnapshot.language` column.

## Design
- Give `ProgressStatsStore` an active language, injected at construction (app passes
  `LanguageManager.shared.current`).
- `allSnapshots` / `snapshots(since:)` return only the active language's snapshots.
- `recordSnapshot(cards:streak:date:)` upserts the single snapshot for (`startOfDay(date)`,
  activeLanguage); a snapshot stamped for another language is never read or overwritten.
- `deduplicate()` groups by (`day`, `language`); same day in two languages is NOT a duplicate.
- `canonicalSnapshot(for:)` is scoped to the active language.
- Rebuild / re-scope the store on language change (mirror the CardStore approach from Story 002) so
  the stats history shown follows the active language and other languages' histories persist.

## Acceptance Criteria
1. `ProgressStatsStore` is constructed with an active language; all reads/writes scope to it.
2. `recordSnapshot` writes/updates only the active language's snapshot for a given day; other
   languages' snapshots for that day are untouched.
3. `deduplicate()` keys on (`day`, `language`): same `day` across two languages coexists; a true
   same-language same-day duplicate still collapses.
4. Switching language swaps the stats history shown and preserves every other language's history;
   switching back restores it exactly (covered by a test).
5. Build passes; new + existing `ProgressStatsStore`/stats tests are green.
