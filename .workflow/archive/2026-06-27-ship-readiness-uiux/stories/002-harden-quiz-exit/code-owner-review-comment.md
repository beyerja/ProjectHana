<!-- code-owner-review -->
## Code-owner review — APPROVED (gate set)

Independent second-eye re-verification of the AC2 (quiz-exit crash) + AC6 (redundant back-nav) change. Reviewed the diff directly (not via the review skill); reached my own verdict, distinct from the implementer and the first reviewer. The required `code-owner-review` status check is posted **success** on head `f4b4a77`.

### AC2 — dismiss-while-advancing race: sound
- `QuizAdvanceScheduler.run` is the correct shared seam: a cancelled sleep throws and returns `false`; an after-wake cancellation is caught by the explicit `Task.isCancelled` guard before side-effects; otherwise side-effects run exactly once. No path runs `advance()`/`persistCardChanges()`/`recordSnapshot()` against a torn-down environment.
- All four answer-driven views (MultipleChoice, Learning, Map, MapLearning) own the advance `Task` in `@State` and cancel it from `.onDisappear` (plus reset `isAdvancing`). View-state mutations after the await are gated on `didRun`/`!Task.isCancelled`, so a mid-advance exit is a guaranteed no-op.
- The two manual-advance text views (Capital, NameFeature) advance synchronously on a "Next" tap — correctly carry no scheduler/Task (no race exists there).
- `QuizAdvanceSchedulerTests` pins all three branches (cancel-during-sleep, cancel-after-wake, happy-path-once) → AC3 met.

### AC6 / AC4 — single back control: complete and reachable
- `.cancellationAction` "Salir" removed from all six quiz views; zero `Salir`/`cancellationAction`/`*.exit` references remain in the quiz sources. The system back chevron is the single control on active-quiz screens.
- Terminal screens (`QuizSummaryView` + the three completion views) use `.navigationBarBackButtonHidden()` with a single "Done" button — exactly one control each, and correctly prevent re-entering a torn-down session.
- `BackButton` is confirmed as the system back-chevron a11y identifier in the committed accessibility dumps, so the retargeted walkthrough scripts resolve to the real surviving control — the consolidation is reachable, not just a script relabel.

### L10n + walkthrough
- The four orphaned keys (`learn.exit`, `map_quiz.exit`, `mcq_quiz.exit`, `capital_quiz.exit`) are removed across all 14 locales via the idempotent `remove-orphaned-exit-keys.py`; grep confirms zero remaining definitions and zero dangling Swift references — the locale set stays balanced.
- `full-walkthrough.json` + `001-localize-mc.json` retargeted from `label: "Salir"` to `identifier: "BackButton"`; new `002-quiz-exit.json` / `002-quiz-exit-map.json` exercise the AC2 race directly.

### Flagged nits — agreed non-blocking
- Dead `@Environment(\.dismiss)` in `MapQuizView` + `MultipleChoiceQuizView` (its only caller was the removed "Salir" button). Confirmed unused; property wrappers don't trip the unused-variable warning so lint stays green. Optional cleanup, not a blocker.

### CI
- `Build & Test`, `Lint (all languages)`, `gitleaks` all green on head `f4b4a77`. No event-miss; no re-trigger needed.

**Verdict: APPROVED.** Gate check `code-owner-review` = success (app id 4144849).
