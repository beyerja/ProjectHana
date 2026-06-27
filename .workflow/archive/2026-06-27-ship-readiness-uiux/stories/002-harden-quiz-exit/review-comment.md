<!-- independent-review -->
## Independent review — APPROVED (round 1)

Fresh cold-context 4-eye review of the AC2 (quiz-exit crash) + AC6 (redundant back-nav) change. No blocking findings.

### AC2 — dismiss-while-advancing race: correct and well-hardened
- The root cause is correctly identified: the old `Task { try? await Task.sleep(...) ; session.advance(); persist; snapshot }` swallowed `CancellationError` but then ran its side-effects against a torn-down SwiftData environment. `QuizAdvanceScheduler.run` fixes this at the right altitude (one shared seam, not per-view bandaids): it returns `false` on a cancelled sleep AND re-checks `Task.isCancelled` after wake before running side-effects.
- All four answer-driven views (MultipleChoice, Learning, Map, MapLearning) own the advance `Task` in `@State` and cancel it from `.onDisappear` (also resetting `isAdvancing`). `.onDisappear` fires on every NavigationStack pop path — back chevron, swipe-back, and programmatic dismiss — so mid-advance exit is a guaranteed no-op.
- Task-ownership is leak-free across question advances: `isAdvancing` gating + the `.disabled` answer controls prevent a second advance Task from being created while one is in flight, so the `@State` handle is never overwritten without the prior Task having completed.
- The two text views (Capital, NameFeature) are manual-advance (user taps "Next") with no auto-advance Task — correctly left without the scheduler.
- `QuizAdvanceSchedulerTests` pins all three branches of the contract (cancel-during-sleep, cancel-after-wake, happy path runs exactly once) — satisfies AC3.

### AC6 — single back control: complete and consistent
- `.cancellationAction "Salir"` removed from all six quiz views; no `Salir`/`cancellationAction`/`*.exit` references remain in the quiz sources. System back chevron is the single control on the active-quiz screens.
- Terminal screens (`QuizSummaryView` + the three completion views) use `navigationBarBackButtonHidden()` with a single "Done" button — exactly one control each, satisfying AC4 for the summary/completion case.

### L10n + walkthrough
- The four orphaned keys (`learn.exit`, `map_quiz.exit`, `mcq_quiz.exit`, `capital_quiz.exit`) are removed from all 14 pre-existing locales via the idempotent `remove-orphaned-exit-keys.py`; grep confirms zero remaining definitions and zero dangling Swift references, so the locale set stays balanced.
- `full-walkthrough.json` + `001-localize-mc.json` retargeted from the `Salir` label to the `BackButton` identifier (the standard UIKit system back-chevron a11y id). New `002-quiz-exit.json` / `002-quiz-exit-map.json` actively exercise the AC2 race (answer → BackButton with no wait → assert non-empty Home tree, looped), which is exactly the right regression shape.

### Non-blocking nits (posted inline, do not gate)
- `@Environment(\.dismiss)` is now dead in `MapQuizView` and `MultipleChoiceQuizView` (its only caller was the removed "Salir" button; the summary path owns its own dismiss). Property wrappers are exempt from the unused-variable warning, so lint won't catch it — consider deleting.

Verdict: **APPROVED**. Inline nits are optional cleanup, not merge blockers.
