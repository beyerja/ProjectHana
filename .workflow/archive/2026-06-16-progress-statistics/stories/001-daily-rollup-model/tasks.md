## Tasks
- [x] 001: Add `DailyProgressSnapshot` @Model (Hanahuac/Models/DailyProgressSnapshot.swift) — CloudKit-ready (all attrs optional/defaulted, no .unique), day boundary + counters + per-category breakdown
- [x] 002: Register `DailyProgressSnapshot.self` in the SwiftData schema in SyncCoordinator.makeModelContainer()
- [x] 003: Add `ProgressStatsStore` (@Observable, Hanahuac/Store/ProgressStatsStore.swift) with recordSnapshot upsert, snapshots(in:) range query, deduplicate(), aggregation helper
- [x] 004: Add `ProgressStatsStoreTests` (in-memory ModelContainer) covering insert, idempotent same-day upsert, multi-day, range ordering, dedupe, per-category aggregation
- [x] 005: just generate (new files), just lint-swift, just build-mac, just test — all green
