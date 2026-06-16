## Tasks
- [x] 001: Construct ProgressStatsStore in AppRootView.onAppear (HanahuacApp.swift) alongside CardStore and inject via .environment(...)
- [x] 002: Add optional `@Environment(ProgressStatsStore.self) private var progressStatsStore: ProgressStatsStore?` to the three quiz views; after each `session.advance()` call record today's snapshot (cards: cardStore.allCards, streak: StreakTracker.currentStreak())
- [x] 003: Extend PreviewStore (withPreviewStore) to also provide a ProgressStatsStore so previews that exercise quiz views build
- [x] 004: Add a recording-hook test: drive a session's advance() against an in-memory store, then recordSnapshot, assert exactly one snapshot for today with expected counters
- [x] 005: just generate (if needed), just lint-swift, just build-mac, just test — all green
