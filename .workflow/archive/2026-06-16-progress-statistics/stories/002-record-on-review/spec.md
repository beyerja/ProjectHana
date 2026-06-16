# Story 002 — Record a daily rollup on every quiz review

## Goal

Capture history going forward by recording/upserting today's `DailyProgressSnapshot` at the same
hook points where `StreakTracker.recordReview()` already fires, so each quiz session writes the
compact daily rollup.

## Design

- The three session sites that call `StreakTracker.recordReview()`:
  - `MapQuizSession.swift` (~line 89)
  - `MultipleChoiceSession.swift` (~line 65)
  - `TextQuizSession.swift` (~line 68)
  must also drive `ProgressStatsStore.recordSnapshot(...)` for the current cards + streak.
- Sessions are plain `@Observable` model objects that today do not hold a `ModelContext`/store.
  Introduce a minimal seam so the snapshot can be recorded without bloating each session:
  - Preferred: inject the `ProgressStatsStore` (or a small `recordProgress` closure) into each
    session from its owning view, OR have the owning views observe session completion and call
    `progressStatsStore.recordSnapshot(cards: cardStore.allCards, streak: StreakTracker.currentStreak())`.
  - The chosen seam must keep sessions unit-testable (no hard dependency on a live SwiftData stack in
    pure-logic tests) and must be cheap to call per review (the upsert is idempotent within a day).
- Construct and inject `ProgressStatsStore` in `AppRootView.onAppear` (`HanahuacApp.swift`) alongside
  `CardStore`, and expose it via `.environment(...)` so views/sessions can reach it. Mirror
  `CardStore`'s injection pattern.
- `PreviewStore` / preview helpers updated so previews and `#Preview`s still build with the new
  environment object.

## Acceptance Criteria

- [ ] Completing a review in each of the three quiz modes records/upserts today's
      `DailyProgressSnapshot` via `ProgressStatsStore`.
- [ ] The recording is idempotent within a day (repeated reviews keep one snapshot, fields refreshed)
      and reflects the latest card state + streak.
- [ ] `ProgressStatsStore` is constructed in `AppRootView` and injected into the environment; preview
      helpers updated so all `#Preview`s build.
- [ ] Sessions remain unit-testable without a live persistent store (seam is injectable/mockable).
- [ ] Unit tests cover the recording hook: after simulating session completion against an in-memory
      store, exactly one snapshot exists for today with the expected counters.
- [ ] `just lint-swift`, build (`just build-mac`), and `just test` pass.

## Out of Scope

- No charts/UI (story 003).
- No change to SM-2 scheduling or `StreakTracker` semantics.
