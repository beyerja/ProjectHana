## Goal

Exiting ANY quiz must reliably return Home without the app terminating, and each quiz screen must offer exactly one clear way back. Covers **AC2** (intermittent quiz-exit crash) and **AC6** (redundant quiz back-navigation).

## Changes

### AC2 — Harden the dismiss-while-advancing crash
- **Root cause:** an unstructured, never-cancelled detached advance `Task` touched SwiftData stores after a dismiss-while-advancing teardown. Each answer-driven view spawned `Task { sleep; session.advance(); cardStore.persistCardChanges(); recordSnapshot(...) }` that was never held or cancelled. Dismissing during the 1–2s sleep popped the view and tore down its `@Environment(CardStoreProvider.self)`-backed `ModelContext`; the orphaned Task then woke and wrote to the gone context = use-after-teardown crash (blank screen → dropped to Home → empty accessibility tree).
- **Fix:** new `Hanahuac/Views/Quiz/QuizAdvanceScheduler.swift` whose `run(...)` sleeps then runs side-effects **only** if its owning Task was not cancelled (catches both a cancelled sleep and a post-wake `Task.isCancelled`). The four answer-driven quiz views (`MultipleChoiceQuizView`, `LearningQuizView`, `MapQuizView`, `MapLearningQuizView`) now own the advance Task in `@State` and cancel it from a new `.onDisappear` — covering the system back chevron, swipe-back, and any dismissal equally. No advance/persist/snapshot work runs after cancellation.

### AC6 — One back-navigation control
- Removed the redundant `.cancellationAction` "Salir" button from all six quiz views (MC, Learning, Map, MapLearning, Capital, NameFeature). The system back chevron is now the single back control.
- Removed the orphaned exit L10n keys (`learn.exit`, `map_quiz.exit`, `mcq_quiz.exit`, `capital_quiz.exit`) from all 14 locales via a committed one-shot script; `l10n-check` stays balanced and green.
- Updated `full-walkthrough.json` and `001-localize-mc.json` to tap `{identifier: BackButton}` instead of `{label: Salir}`.
- Added new walkthrough scripts `002-quiz-exit.json` (MC answer → BackButton → Home, looped x3) and `002-quiz-exit-map.json` (Map mapTap → BackButton → Home, looped x3).

### Regression test
- `HanahuacTests/QuizAdvanceSchedulerTests.swift` — 3 tests pinning the cancellation contract: cancelled-during-sleep, cancelled-after-sleep, and the happy path.

## Test plan
- [x] `just lint` passes (SwiftLint 0 violations, swiftformat clean, ruff clean, l10n-check pass)
- [x] Full `HanahuacTests` suite green (incl. the 3 new `QuizAdvanceSchedulerTests`)
- [ ] AC9 live walkthrough before/after evidence capture (screenshots + a11y dumps)

## Known caveat
AC9 live walkthrough evidence capture is **pending** a CoreSimulator daemon recovery in this environment (daemon version mismatch — no bootable iPhone 17 / iOS 26.5 sim; needs a machine restart, out of an agent's scope). As a fallback the full unit suite was verified green via the Mac Catalyst destination. CI will exercise the iOS-simulator path. The two new walkthrough scripts are ready to drive the live evidence once the simulator is healthy.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
