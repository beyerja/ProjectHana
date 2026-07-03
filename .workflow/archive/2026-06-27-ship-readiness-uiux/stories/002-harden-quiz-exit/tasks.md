# Tasks — 002 Harden quiz exit + resolve redundant back-navigation

Context (grounding):
- Quizzes are pushed onto HomeView's `NavigationStack` via `.navigationDestination(for: QuizRoute.self)`,
  so every quiz screen gets the SYSTEM back chevron PLUS a `.cancellationAction` toolbar exit button
  labeled "Salir" — that is the AC6 redundancy.
- AC2 root cause (diagnosed): MC / Learning / Map / MapLearning each spawn an UNSTRUCTURED detached
  `Task { try? await Task.sleep(...); session.advance(); cardStore.persistCardChanges();
  progressStatsStore?.recordSnapshot(...) }` (auto-advance / onChange-of-answerState) that is never
  cancelled. Tapping exit during the sleep dismisses + tears down the view's environment, then the
  Task later touches the SwiftData-backed `cardStore` / `progressStatsStore` after teardown =
  use-after-teardown crash (the dismiss-while-advancing race).
- "Salir" exit buttons resolve from L10n keys: `mcq_quiz.exit`, `learn.exit`, `map_quiz.exit`,
  `capital_quiz.exit` (NameFeature reuses `capital_quiz.exit`). All map to "Salir" in es-ES + es-MX.
- Walkthrough scripts that target the "Salir" label: `scripts/full-walkthrough.json` (line 13),
  `scripts/001-localize-mc.json` (line 22).
- Completion / summary screens (`QuizSummaryView`, learning/graduation completion views,
  CapitalQuizView/NameFeatureQuizView/LearningQuizView/MapLearningQuizView completion) use
  `.navigationBarBackButtonHidden()` — removing the toolbar exit must keep a deliberate single way
  back on those terminal screens (their existing "Done" button), so they are NOT left with zero exits.

## Tasks
- [ ] 001: Diagnose + document the dismiss-while-advancing race in the story log. Capture the exact
  failure mode (detached `Task` outliving view teardown, touching `cardStore` ModelContext /
  `progressStatsStore` after the environment is gone) and enumerate every site: the auto-advance
  `Task` in `MultipleChoiceQuizView.scheduleAdvance`, `LearningQuizView.scheduleAdvance`,
  `MapQuizView` `onChange(of: session.answerState)`, and `MapLearningQuizView`
  `onChange(of: session.answerState)`. Define the chosen hardening contract (own the advance Task in
  `@State`, cancel on exit + `onDisappear`, no teardown/persist work after cancellation).
- [ ] 002: Harden `MultipleChoiceQuizView` auto-advance teardown. Hold the advance `Task` in a
  `@State` handle, check `Task.isCancelled` after the sleep before calling `session.advance()` /
  `persistCardChanges()` / `recordSnapshot()`, cancel it from the exit action and from `.onDisappear`,
  and reset `isAdvancing`. Exit must never run persist/snapshot after dismissal.
- [ ] 003: Apply the same advance-Task cancellation hardening to `LearningQuizView`
  (`scheduleAdvance`).
- [ ] 004: Apply the same advance-Task cancellation hardening to `MapQuizView`
  (`onChange(of: session.answerState)` advance Task) and reset map/`isAdvancing` state on teardown.
- [ ] 005: Apply the same advance-Task cancellation hardening to `MapLearningQuizView`
  (`onChange(of: session.answerState)` advance Task).
- [ ] 006: Resolve AC6 — remove the redundant `.cancellationAction` "Salir" toolbar exit button from
  all six quiz views (`MultipleChoiceQuizView`, `LearningQuizView`, `MapQuizView`,
  `MapLearningQuizView`, `CapitalQuizView`, `NameFeatureQuizView`), keeping the system back chevron as
  the single back control (fits the push-nav model). Ensure the cancel/dismiss work that the "Salir"
  button performed (Task cancellation from task 002–005) is wired to view teardown (`onDisappear`) so
  the back chevron path is equally hardened. Confirm terminal completion/summary screens
  (`navigationBarBackButtonHidden`) still expose exactly one way out via their existing "Done" button.
- [ ] 007: Clean up the now-unused exit L10n keys ONLY if fully orphaned: grep `mcq_quiz.exit`,
  `learn.exit`, `map_quiz.exit`, `capital_quiz.exit` across the codebase; remove dead keys from every
  `*.lproj/Localizable.strings` (en, es-MX, es-ES, ca, base) keeping all locales in sync, or leave
  them if any reference remains. Run the L10n completeness gate so no locale drifts.
- [ ] 008: Update `.workflow/ui-walkthrough/scripts/full-walkthrough.json` — replace the
  `{ "action": "tap", "label": "Salir" }` step (line 13) with a back step targeting the system back
  chevron (`{ "action": "tap", "identifier": "BackButton" }`) so the walkthrough stays green after
  "Salir" is removed.
- [ ] 009: Update `.workflow/ui-walkthrough/scripts/001-localize-mc.json` — replace its "Salir" tap
  (line 22) with the `BackButton` back step. (Run output dirs are git-ignored; only scripts are
  tracked — no committed PNG/JSON run evidence references "Salir", so only the two scripts change.)
- [x] 010: Add a regression test for the exit path (AC3). Prefer a fast unit/logic test asserting the
  advance side-effects do NOT run after cancellation (e.g. extract the post-sleep advance step so a
  cancelled handle is a no-op, or assert via the session that `advance()`+persist are skipped on
  cancel) in `HanahuacTests`. If a unit test cannot reach the race, add a `HanahuacUITests` test that
  drives MC: answer → tap back during the advance window → assert the app is on Home with a non-empty
  element tree, looped several times.
- [x] 011: Author `.workflow/ui-walkthrough/scripts/002-quiz-exit.json` (AC9): open MC
  (`home.mode.multipleChoice`) → answer (`quiz.answer.0`) → tap back (`BackButton`) → assert Home is
  reached (`home.settings` present) with a non-empty tree; loop the answer→exit cycle several times
  (re-enter MC each loop) with `dumpTree` + `screenshot` after each exit.
- [x] 012: Author a second variant script for at least one other quiz mode (e.g.
  `.workflow/ui-walkthrough/scripts/002-quiz-exit-map.json`): open a Map quiz, `mapTap` an answer,
  tap back during/after the advance, assert non-empty Home tree, looped. Covers AC1's "at least one
  other mode".
- [~] 013: BLOCKED (environment). Capture before/after LIVE evidence (AC9). Run `just ui-walkthrough` for 002-quiz-exit +
  the variant against the booted iPhone 17 / iOS 26.5 sim; read screenshots AND accessibility dumps;
  confirm BEFORE shows two back controls / crash-prone path and AFTER shows the single control and a
  non-empty Home tree across repeated exits. Reference the run artifact dirs in the story/verify log.
  (Use `HANA_FEATURE_SLUG=ship-readiness-uiux`.)
- [x] 014: Run `just generate` ONLY if `project.yml` changed (no hand-edits to the pbxproj). Then run
  `just lint` and `just test` (with `HANA_FEATURE_SLUG=ship-readiness-uiux`) and fix any failures so
  both pass (AC6 of spec / constraints).
