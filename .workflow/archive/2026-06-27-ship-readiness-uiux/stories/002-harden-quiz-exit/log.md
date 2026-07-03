# Log — 002 Harden quiz exit + resolve redundant back-navigation

2026-06-26T16:53:33Z break-tasks: DONE, 14 tasks

2026-06-26 implement-story: task 001 — diagnosis confirmed against code.
AC2 root cause (CONFIRMED by reading the four answer-driven views):
- MultipleChoiceQuizView.scheduleAdvance(), LearningQuizView.scheduleAdvance(),
  MapQuizView `.onChange(of: session.answerState)`, MapLearningQuizView `.onChange(of: session.answerState)`
  each spawn an UNSTRUCTURED detached `Task { try? await Task.sleep(...); <advance>; cardStore.persistCardChanges(); progressStatsStore?.recordSnapshot(...) }`.
- The Task is not held anywhere and is never cancelled. It captures the struct view, whose `cardStore`
  computed property resolves through the `@Environment(CardStoreProvider.self)` provider, which is backed
  by a SwiftData ModelContext. Tapping the exit control (or system back) during the 1.0–2.0s sleep calls
  `dismiss()`, popping the view off HomeView's NavigationStack and tearing down its environment. The orphaned
  Task wakes after the sleep and calls `session.advance()` + `cardStore.persistCardChanges()` +
  `recordSnapshot(...)` on a context whose owning environment is gone = use-after-teardown crash
  (blank white screen → dropped to iOS home → empty accessibility tree). This is the dismiss-while-advancing race.
- Competing theories RULED OUT: (a) it is NOT a SwiftUI re-entrancy/navigation-stack bug — the back chevron and
  "Salir" both call the same `dismiss()`; the crash is in the post-sleep store write, not the pop. (b) NOT a
  session-logic bug — `session.advance()` alone is value mutation; the crash needs the persistence write after
  teardown. (c) NOT specific to "Salir" — any dismissal (chevron, swipe-back, "Salir") during the sleep triggers it.
Hardening contract: own the advance `Task` in `@State var advanceTask`, check `Task.isCancelled` immediately
after the sleep and bail (no advance/persist/snapshot) if cancelled, cancel it from `.onDisappear` (which covers
BOTH the back chevron and any dismissal), and reset `isAdvancing`. No teardown/persist work runs after cancellation.

2026-06-26 implement-story: tasks 002-014.
- AC2 hardening (002-006): added Hanahuac/Views/Quiz/QuizAdvanceScheduler.swift — a testable
  `QuizAdvanceScheduler.run(afterNanoseconds:sleep:sideEffects:)` that sleeps then runs side-effects
  ONLY if the owning Task is not cancelled (catches a cancelled sleep AND checks Task.isCancelled after
  wake). Routed the four answer-driven views (MultipleChoiceQuizView.scheduleAdvance,
  LearningQuizView.scheduleAdvance, MapQuizView + MapLearningQuizView `.onChange(of: answerState)`)
  through it; each now owns the advance Task in `@State var advanceTask` and cancels it + resets
  isAdvancing from a new `.onDisappear` (covers the system back chevron / swipe-back path equally).
- AC6 (006): removed the `.cancellationAction` "Salir" toolbar exit from ALL SIX quiz views (MC,
  Learning, Map, MapLearning, Capital, NameFeature). System back chevron is now the single back
  control. Terminal completion/summary screens still expose exactly one exit via their existing "Done"
  button (navigationBarBackButtonHidden, unchanged).
- L10n cleanup (007): exit keys (learn.exit, map_quiz.exit, mcq_quiz.exit, capital_quiz.exit) were
  referenced only by the removed buttons → fully orphaned. Removed from all 14 *.lproj via a committed
  one-shot script scripts/remove-orphaned-exit-keys.py (56 lines removed). l10n-check PASSES (157
  canonical keys, all required locales complete) — the gate's canonical set is the union across
  locales so removing everywhere stays balanced.
- Walkthrough scripts (008-009): full-walkthrough.json + 001-localize-mc.json now tap
  {identifier: BackButton} instead of {label: Salir}.
- Regression test (010): HanahuacTests/QuizAdvanceSchedulerTests.swift — 3 tests pinning the
  cancellation contract (cancelled-during-sleep, cancelled-after-sleep, happy path). All pass.
- New scripts (011-012): .workflow/ui-walkthrough/scripts/002-quiz-exit.json (MC answer→BackButton→Home,
  looped x3, dumpTree+screenshot after each exit) and 002-quiz-exit-map.json (Map mapTap→BackButton→Home,
  looped x3).
- 014: new Swift files added so ran `just generate` (folder-enumerated sources; project.yml NOT edited,
  pbxproj NOT hand-edited). `just lint` PASSES (SwiftLint 0 violations, swiftformat clean, ruff clean,
  l10n-check pass).
- TESTS: `just test` (iOS Simulator destination) and `just ui-walkthrough` (task 013 live evidence) are
  BLOCKED by an environment-level CoreSimulator daemon failure: "CoreSimulator is out of date. Current
  version (1051.54.0) is older than build version (1051.55.0)." simctl hangs/returns nothing; no
  iPhone 17 / iOS 26.5 sim is bootable. launchctl-remove / pkill of CoreSimulator did not recover it —
  needs a machine restart (out of an agent's scope). As a fallback I ran the FULL HanahuacTests suite
  via the Mac Catalyst destination: ** TEST SUCCEEDED **, 0 failures across all suites incl. the 3 new
  QuizAdvanceSchedulerTests. Task 013 (before/after live screenshots + a11y dumps) MUST be re-run by the
  next agent once the simulator is healthy; the two new scripts are ready to drive it.

2026-06-26T17:13:01Z implement-story: DONE — tasks 001-012 + 014 complete (AC2 advance-Task cancellation
hardening across the 4 answer-driven views, AC6 "Salir" removal from all 6 quiz views, orphaned exit
L10n keys removed from 14 locales, regression test + 2 walkthrough scripts, project regenerated, lint +
full unit suite green). Commit 83dde7a. Task 013 (LIVE walkthrough evidence) BLOCKED by a CoreSimulator
daemon version mismatch in this environment (no bootable iPhone 17 / iOS 26.5 sim; needs machine
restart) — full test suite verified via Mac Catalyst as a fallback.

2026-06-26T17:20:00Z create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/185

2026-06-26 independent-review: APPROVED — AC2 cancellation contract correct (shared QuizAdvanceScheduler skips side-effects on cancelled sleep AND post-wake Task.isCancelled; .onDisappear cancels the @State advance Task on every pop path; no Task-handle leak across advances), 3 regression tests pin it (AC3); AC6 single-control complete across all 6 quiz views + terminal Done-only screens (AC4); orphaned exit keys removed from all 14 locales, zero dangling refs; walkthrough retargeted to BackButton and exercises the race. Two non-blocking nits (dead @Environment(\.dismiss) in MapQuizView + MultipleChoiceQuizView) posted inline. NOTE: live ui-walkthrough evidence (task 013, AC9) remains deferred per the CoreSimulator block — a verify-story concern, not a code defect.

2026-06-26T17:29:20Z code-owner-review: APPROVED — independent 2nd-eye re-verify; AC2 cancellation contract sound, AC6 single back control (BackButton) reachable, L10n balanced across 14 locales, CI green. Gate check code-owner-review=success on f4b4a77 (app id 4144849, read-back confirmed).

2026-06-26 merge-pr: DONE — PR #185 squash-merged to main as a7c655e, story branch deleted (remote + local), feat/ship-readiness-uiux fast-forwarded to origin/main.

2026-06-26 verify-story: DONE (code-level ACs all PASS; AC9 live evidence BLOCKED — environment).
Verified against the MERGED code at a7c655e (= origin/main).
- AC2 (dismiss-while-advancing): QuizAdvanceScheduler.run(afterNanoseconds:sleep:sideEffects:) runs
  side-effects ONLY if the owning Task was not cancelled (catches cancelled sleep AND post-wake
  Task.isCancelled). All four answer-driven views (MultipleChoiceQuizView, LearningQuizView,
  MapQuizView, MapLearningQuizView) own the advance Task in @State var advanceTask and cancel it +
  reset isAdvancing from a new .onDisappear (covers system back chevron / swipe-back). CONFIRMED by
  reading each view.
- AC3 (regression test): HanahuacTests/QuizAdvanceSchedulerTests.swift (3 tests) pins the
  cancellation contract — PASS (cancelled-during-sleep, cancelled-after-sleep, happy path).
- AC4 (single back control): no "Salir"/cancellationAction/extra toolbar back control in any of the
  6 quiz views; system back chevron is the single control; terminal screens keep a single "Done"
  (learn.done) under navigationBarBackButtonHidden(). Orphaned exit L10n keys removed from all
  locales (0 dangling refs).
- AC5/scripts: full-walkthrough.json + 001-localize-mc.json retargeted to BackButton (no Salir);
  002-quiz-exit.json (MC answer->BackButton->Home, looped x3, dumpTree+screenshot after each exit)
  and 002-quiz-exit-map.json (mapQuiz, looped) both present.
- AC6: `just lint` PASS (all linters + l10n-check). Tests: iOS-sim `just test` blocked by the same
  CoreSimulator daemon mismatch; verified via Mac Catalyst -only-testing:HanahuacTests =>
  ** TEST SUCCEEDED **, full HanahuacTests suite 474 tests / 0 failures (the unscoped Catalyst run
  reports ** TEST FAILED ** only because the HanahuacUITests XCUITest target cannot launch under
  Mac Catalyst — not a unit failure).
- AC9 LIVE EVIDENCE: BLOCKED (environment). CoreSimulator framework is 1051.54 but the running
  daemon expects 1051.55.0; `xcrun simctl list devices booted` and even `xcrun simctl help` hang
  with no output; SimDeviceService/CoreSimulatorService show failed status. No bootable iPhone 17 /
  iOS 26.5 sim; needs a machine restart (out of an agent's scope). The two walkthrough scripts are
  ready to capture before/after screenshots + a11y dumps once the sim is healthy.
