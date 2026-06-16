# Story 003 — Charts section in StatsView (Swift Charts)

## Goal

Visualize the accumulated daily rollups graphically inside the existing `StatsView`, below the
current snapshot cards, with a time-range selector and an optional category filter.

## Design

- Extend `Hanahuac/Views/Progress/StatsView.swift` with a new charts section appended BELOW
  `summarySection` / `categoryBreakdownSection` / `tierLegendSection` (do NOT create a new screen;
  `ProgressPlaceholderView` stays unused).
- Read snapshots from the injected `ProgressStatsStore` (`@Environment`).
- Controls:
  - Time-range selector (segmented `Picker`): 7 days / 30 days / all-time.
  - Category filter: "All" by default plus Country / River / Mountain / Sea (reuse
    `CardCategory.allCases` + `displayName`). When a category is selected the charts use that
    category's per-category counters from the snapshot.
- Charts (Swift Charts, `import Charts`; no new dependency):
  - Mastery growth over time: line/area of Review + Mastered counts per day.
  - Daily reviews completed: bar per day.
  - Cards graduated per day and/or streak history as appropriate (at least the four metrics from the
    feature spec are represented across the charts).
  - Empty/insufficient-data state: a friendly placeholder when there are 0–1 snapshots.
- Localization: every new user-facing string added to ALL FOUR `Localizable.strings`
  (`en`, `de`, `es-MX`, `fr`) under a `stats.charts.*` key namespace, following the existing `L10n`
  pattern (use `L10n["…"]`). Keys must exist in all four files with no missing entries.
- Keep the view re-localizing on language switch (`.id(languageManager.current)` already present).

## Acceptance Criteria

- [ ] `StatsView` shows a charts section below the existing cards, rendering the daily rollups with
      Swift Charts.
- [ ] Time-range selector (7 / 30 / all-time) filters the charted range.
- [ ] Category filter (All + 4 categories) switches the charts between totals and per-category data.
- [ ] Metrics represented: mastery growth (Review/Mastered over time), daily reviews completed, cards
      graduated per day, and streak/active-day history.
- [ ] Graceful empty-state when there is insufficient history.
- [ ] All new strings present in en, de, es-MX, fr `Localizable.strings` (parity verified — no key
      missing from any locale).
- [ ] `#Preview` builds with seeded sample snapshots (extend `PreviewStore`/preview helpers as needed).
- [ ] `just lint-swift`, build (`just build-mac`), and `just test` pass.

## Out of Scope

- No new persistence model (uses story 001's model).
- No remote analytics or export.
