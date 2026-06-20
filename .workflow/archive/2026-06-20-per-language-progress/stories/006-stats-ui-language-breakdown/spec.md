# Story 006 — Stats UI: active-language default + per-language breakdown

## Goal
The stats screen defaults to showing the ACTIVE language's progress (which it already does once
Stores are language-scoped), and additionally offers an option to view a per-language breakdown /
comparison across all languages.

## Design
- Default view (`StatsView`) shows the active language's cards/snapshots/streak — already true once
  Stories 002–004 land; confirm the active-language label is visible so the user knows which track
  they're viewing.
- Add a per-language breakdown: a view (e.g. a section or a sheet/segmented toggle in `StatsView`)
  that, for each `AppLocale`, shows a compact summary of that language's progress — e.g. cards
  mastered / in-review / due, current streak, and total reviews. Implement by reading each
  language's data:
  - Build a small read-only helper that, given an `AppLocale`, returns its summary by querying the
    SwiftData context filtered by `language` (for cards/snapshots) and the per-language streak key.
    Do NOT mutate or re-seed other languages when computing the summary (read-only).
- Languages with no progress show zeros (consistent with "fresh start" semantics).
- Keep it localized and consistent with existing `StatsView` styling.

## Acceptance Criteria
1. `StatsView` defaults to the active language's progress and labels which language is shown.
2. A per-language breakdown/comparison view lists every `AppLocale` with its own summary
   (mastered / review / due / streak / reviews), read-only, with zeros for empty languages.
3. The breakdown reads each language's data correctly without mutating other languages' progress.
4. Build passes; a test covers the breakdown summary computation (per-language isolation); existing
   tests stay green.
