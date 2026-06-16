# Feature: Progress Statistics Over Time

## Goal

Persist user-progress statistics over time and visualize them graphically inside the app.
The app currently stores no historical/time-series data; the existing `StatsView`
(`Hanahuac/Views/Progress/StatsView.swift`, shown via `HomeView.swift:205`) is point-in-time only
(current mastery-tier counts per category, due-today count, streak int in `UserDefaults` via
`StreakTracker`). This feature adds a persisted daily rollup and a Swift Charts section so users can
see their learning trends.

## Status

Feature is CLARIFIED — spec finalized and user-approved ("recommended defaults"). No further user
clarification required.

## Context (from codebase investigation)

- Stack: SwiftUI · SwiftData · MapKit · Swift Charts (no new external dependencies); iOS 17+/macOS 14+.
- `ReviewCard` (`@Model`, SwiftData) holds only current SM-2 state; no review history.
- `StreakTracker.recordReview()` is called at the end of every quiz session:
  `MapQuizSession.swift:89`, `MultipleChoiceSession.swift:65`, `TextQuizSession.swift:68` — these are
  the natural hook points to also record a daily progress rollup.
- `MasteryTier.classify(card)` maps a `ReviewCard` to New / Learning / Review / Mastered.
- `ProgressPlaceholderView` is unused; do NOT create a separate screen.

## Acceptance Criteria

- [ ] A new SwiftData `@Model` stores a compact **daily rollup** snapshot of progress. It follows the
      SAME CloudKit-mirror-ready rules as `ReviewCard`: every stored attribute optional or defaulted;
      NO `@Attribute(.unique)`; uniqueness-per-day enforced in app logic (upsert). It integrates with
      the existing `SyncCoordinator` / CloudKit-ready container approach.
- [ ] Metrics captured per day: mastery growth (counts reaching Review / Mastered), daily reviews
      completed, cards graduated that day, and streak / active-day history.
- [ ] Granularity is ONE daily rollup snapshot per day, upserted on each `recordReview`; retained
      indefinitely.
- [ ] `recordReview` hooks at the three quiz-session sites also record/upsert the daily rollup.
- [ ] `StatsView` is extended with a new charts section BELOW the existing snapshot cards (no separate
      screen). Uses Swift Charts.
- [ ] UI has a time-range selector: 7 days / 30 days / all-time.
- [ ] UI shows totals by default, with an optional category filter (Country / River / Mountain / Sea).
- [ ] All new user-facing strings are added to every `Localizable.strings` (en, de, es-MX, fr)
      following the existing `L10n` pattern.
- [ ] Unit tests cover the new rollup recording/aggregation logic, mirroring existing
      `HanahuacTests` conventions.
- [ ] Project checks pass: swiftlint / swiftformat / build / tests via `just`.

## Constraints

- Zero new external dependencies. Use Swift Charts (built in).
- New model must be CloudKit-mirror-ready (all attributes optional/defaulted, no `.unique`,
  app-logic upsert for per-day uniqueness) and wire into the existing sync/container setup.
- Follow CLAUDE.md: prefer Read/Grep/Glob over Bash for inspection; reserve Bash for git/gh/just/xcodebuild.
- Localization parity across all four locales is mandatory.
- All CI checks here are fast (lint/format/build/test) and block the PR; no slow/async scans are
  introduced by this feature.

## Out of Scope

- No separate analytics/stats screen (extend existing `StatsView` only).
- No backfill of historical data from before the feature ships (history accrues going forward).
- No new external analytics SDKs or remote telemetry.
- No changes to the SM-2 scheduling algorithm or `ReviewCard` schema.
- No per-card detailed review-event log (only the compact daily rollup).
