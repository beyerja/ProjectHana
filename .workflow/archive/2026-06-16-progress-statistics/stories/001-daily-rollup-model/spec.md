# Story 001 — Daily progress rollup model + stats store

## Goal

Introduce the persisted time-series foundation: a compact daily-rollup SwiftData `@Model` plus a
store that upserts one snapshot per day and aggregates snapshots for charting. This is the
abstraction every later story plugs into, so it ships first and compiles on its own (the store is
wired into the schema but not yet called by quiz sessions or the UI).

## Design

- New `@Model DailyProgressSnapshot` in `Hanahuac/Models/DailyProgressSnapshot.swift`, CloudKit-mirror-ready
  exactly like `ReviewCard`:
  - every stored attribute optional or defaulted; NO `@Attribute(.unique)`.
  - `day: Date = .now` stored as the `Calendar.startOfDay` boundary; uniqueness-per-day enforced in
    app logic (upsert), not by the store.
  - stored counters (all defaulted Ints): `reviewsCompleted`, `cardsGraduated`, and per-day tier
    totals `reviewCount` (cards at Review tier) and `masteredCount` (cards at Mastered tier), plus
    `streak`. Per-category breakdown stored as four parallel mastered/review counters keyed by
    category, OR a compact encoding — choose the simplest scheme that satisfies the category filter in
    story 003 while keeping all attributes optional/defaulted and CloudKit-safe.
  - an `init` mirroring `ReviewCard`'s style, plus a convenience computed accessor if useful.
- New `ProgressStatsStore` (`@Observable`, `Hanahuac/Store/ProgressStatsStore.swift`) holding a
  `ModelContext`, mirroring `CardStore`'s shape:
  - `recordSnapshot(cards:streak:date:)` — computes today's rollup from the current `[ReviewCard]`
    (using `MasteryTier.classify`) and **upserts** the single snapshot for `startOfDay(date)`
    (fetch-existing-or-insert, then update fields, then save). Duplicate-safe: if multiple snapshots
    for the same day exist (CloudKit merge), collapse to one deterministically.
  - `snapshots(in:)` / aggregation accessor returning ordered snapshots for a date range, plus a
    `deduplicate()` mirroring `CardStore`.
- Register the model in the SwiftData schema: add `DailyProgressSnapshot.self` to the `Schema([...])`
  in `SyncCoordinator.makeModelContainer()` so the persistent store includes it. Mirror it in test
  containers.

## Acceptance Criteria

- [ ] `DailyProgressSnapshot` `@Model` exists, all stored attributes optional/defaulted, no `.unique`,
      with a doc comment explaining CloudKit compatibility (mirroring `ReviewCard`).
- [ ] `DailyProgressSnapshot.self` added to the schema in `SyncCoordinator.makeModelContainer()`.
- [ ] `ProgressStatsStore.recordSnapshot(...)` upserts exactly one snapshot per calendar day
      (idempotent within a day) and persists.
- [ ] `recordSnapshot` correctly derives reviews-completed, cards-graduated-today, per-tier counts
      (Review/Mastered) and per-category breakdown from the supplied cards + streak.
- [ ] A `deduplicate()` collapses multiple same-day snapshots to one deterministically.
- [ ] Unit tests (`ProgressStatsStoreTests`, in-memory `ModelContainer` like `CardStoreTests`) cover:
      first-snapshot insert, same-day idempotent upsert (count stays 1, fields update), multi-day
      accumulation, range query ordering, dedupe, and per-category aggregation.
- [ ] `just lint-swift`, build (`just build-mac`), and `just test` pass.

## Out of Scope

- No quiz-session wiring (story 002).
- No UI/charts (story 003).
