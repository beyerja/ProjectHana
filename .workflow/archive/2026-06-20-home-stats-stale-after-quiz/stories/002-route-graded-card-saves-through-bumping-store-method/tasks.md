## Tasks

- [x] 001: Add `func persistCardChanges()` to `CardStore` (Hanahuac/Store/CardStore.swift) — an explicit
      entry point that persists graded/reviewed `ReviewCard` mutations made on the shared `ModelContext`
      and bumps the revision signal. Body: `try? modelContext.save()` then `markChanged()` (reuse story
      001's existing private `markChanged()` helper; do NOT add a second bump path). Add a doc comment
      explaining it is the routing point quiz views call after each grade so the home pills update even
      if `recordSnapshot` is skipped. Do not change `upsert`/`seedIfNeeded`/`resetAll`/`deduplicate`.
- [x] 002: Route the MultipleChoice (review) save through the store. In
      `MultipleChoiceQuizView.scheduleAdvance` (Hanahuac/Views/Quiz/MultipleChoice/MultipleChoiceQuizView.swift),
      call `cardStore.persistCardChanges()` immediately after `session.advance()` and before/around the
      existing `progressStatsStore?.recordSnapshot(...)`. Behavior unchanged otherwise.
- [x] 003: Route the MapQuiz (review) save through the store. In `MapQuizView` quizBody's
      `onChange(of: session.answerState)` Task (Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift), call
      `cardStore.persistCardChanges()` after `session.advance()`, alongside the existing
      `recordSnapshot(...)`. MapQuizSession's dual-penalty mutates a second card in the same context —
      one save covers both.
- [x] 004: Route the TextQuiz capital paths through the store. In `CapitalQuizView`
      (Hanahuac/Views/Quiz/TextQuiz/CapitalQuizView.swift) call `cardStore.persistCardChanges()` in both
      `advancePending(_:)` (pending/review) and `advanceLearning(_:)` (new/learning), after the session
      mutation and alongside the existing `recordSnapshot(...)`.
- [x] 005: Route the TextQuiz name-feature paths through the store. In `NameFeatureQuizView`
      (Hanahuac/Views/Quiz/TextQuiz/NameFeatureQuizView.swift) call `cardStore.persistCardChanges()` in
      both `advancePending(_:)` and `advanceLearning(_:)`, after the session mutation and alongside the
      existing `recordSnapshot(...)`.
- [x] 006: Wire `CardStore` into `LearningQuizView` and route its graded saves. Add
      `@Environment(CardStore.self) private var cardStore` to
      Hanahuac/Views/Quiz/LearningQuizView.swift (the store is injected app-wide in HanahuacApp via
      `.environment(store)`, so it is available), and call `cardStore.persistCardChanges()` inside
      `scheduleAdvance` after `session.recordCorrect()` / `session.recordWrong()`. This view currently
      records NO snapshot and makes NO store call, so its graduation/streak mutations rely solely on
      SwiftData autosave and never bump the revision — this is the core staleness gap for the
      multiple-choice "new" pile. Confirm the `#Preview` still resolves the store (it uses
      `.withPreviewStore()`, which injects a CardStore).
- [x] 007: Wire `CardStore` into `MapLearningQuizView` and route its graded saves. Add
      `@Environment(CardStore.self) private var cardStore` to
      Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift and call `cardStore.persistCardChanges()`
      inside the `onChange(of: session.answerState)` Task after `session.recordCorrect()` /
      `session.recordWrong()`. Same gap as task 006 for the map "new" pile (graduation + dual-penalty
      streak resets). Verify the `#Preview` (`.withPreviewStore()`) still resolves the store.
- [x] 008: Add tests for the new entry point in HanahuacTests/CardStoreTests.swift: (a)
      `persistCardChanges()` bumps `revision` (call it, assert `revision` increased); (b) it persists a
      mutation made on a fetched live card — mutate a seeded/inserted card's `consecutiveCorrect` or
      `hasGraduated`, call `persistCardChanges()`, then re-fetch via a fresh `FetchDescriptor` (or new
      `CardStore` on the same context) and assert the change is read back. Follow the existing in-memory
      `ModelContainer` setup pattern in the file.
- [x] 009: Run `just -f <worktree>/justfile lint` and `just -f <worktree>/justfile test`; fix any
      lint/test failures introduced by the routing changes. Confirm SR grading behavior is unchanged
      (no SR field computation was touched — only save routing was added).
