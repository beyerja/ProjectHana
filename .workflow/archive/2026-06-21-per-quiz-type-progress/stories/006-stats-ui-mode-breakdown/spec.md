# Story 006 — Progress screen: aggregated default + per-mode breakdown toggle

## Goal
The Progress screen keeps showing mode-aggregated totals by default (matching today's numbers), and
adds an option/toggle to view the per-mode breakdown (individual mode totals).

## Background
`StatsView` reads the active-language `CardStore` (now via the provider) and `ProgressStatsStore` to
render mastery tiers, daily history, and category filters. Story 003 records per-mode snapshots plus
the aggregated `quizMode == ""` rollup. `LanguageProgressSummary` already exists as the per-language
breakdown precedent to mirror for the UI pattern.

## Scope
- Add a per-mode breakdown view to the Progress screen, defaulting to the aggregated view (current
  behavior, byte-identical numbers). Provide a toggle/segmented control (e.g. "All modes" vs.
  per-mode) — mirror the structure/affordance of the existing per-language breakdown
  (`LanguageProgressSummary`) for consistency.
- The breakdown shows per-mode totals (e.g. reviews/mastered/cards per mode) sourced from the per-mode
  snapshots (Story 003) and/or per-mode `CardStore`s (Story 002 provider). Only modes with data (or all
  four, with zeros) — pick the clearer presentation; `typeCapital` naturally shows only Countries data.
- Localize any new UI strings across the shipped locales (follow the project's L10n convention used by
  the existing summary view).
- Default view and existing aggregate numbers are unchanged when the toggle is in its default state.

## Acceptance Criteria
- [ ] Progress screen defaults to mode-aggregated totals identical to today's numbers (after
      migration).
- [ ] A toggle reveals a per-mode breakdown showing each mode's totals, backed by the per-mode data
      from Stories 002/003.
- [ ] `typeCapital` appears only with Countries data (no fabricated rows for categories it doesn't
      serve).
- [ ] New UI strings are localized across the shipped locales.
- [ ] `just build` and `just test` green, including any new stats/UI tests.
