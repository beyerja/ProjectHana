# Story 003 — Record daily progress snapshots per mode (aggregated default preserved)

## Goal
Record enough per-mode daily stats to back a per-mode breakdown, WITHOUT changing the default
aggregated numbers the Progress screen shows today. After this story the data layer holds both the
aggregated `(day, language)` rollup (unchanged behavior) and per-`(day, language, quizMode)` rollups.

## Background
`ProgressStatsStore(modelContext:language:)` writes one `DailyProgressSnapshot` per `(day, language)`
via `recordSnapshot(cards:streak:date:)`, computing mastery/review counts from the passed cards. Story
001 added the `quizMode` column to `DailyProgressSnapshot`. Story 002 made cards per-mode and added the
`CardStoreProvider`. Quiz views call `progressStatsStore?.recordSnapshot(...)` after grading, passing
the (now per-mode) card set.

## Scope
- Make `ProgressStatsStore` able to record/read both the aggregated snapshot (`quizMode == ""`, the
  default the Progress screen reads today) AND a per-mode snapshot keyed by
  `(day, language, quizMode)`. Options: scope a store instance by `quizMode` (mirroring CardStore +
  provider), or add a `mode:` parameter to `recordSnapshot`/fetch accessors. Either way:
  - The aggregated `quizMode == ""` snapshot must keep matching today's totals (sum across modes), so
    the existing default Progress view is byte-for-byte unchanged after migration.
  - Per-mode snapshots are written with the grading mode's token.
  - Dedup / `canonicalSnapshot` keys on `(day, language, quizMode)`; the same `day` in a different
    mode (or `""` aggregate) is not a duplicate.
- Update the quiz views' `recordSnapshot(...)` call sites so each records into both its mode's per-mode
  snapshot and the aggregated rollup (or routes through a provider/helper that updates both), passing
  the correct mode token. The aggregate must reflect all modes' cards (e.g. recompute from the
  provider's union of cards, or accumulate), so switching modes never makes the aggregate drop.
- `StreakTracker` is untouched — streak stays per-language and shared across modes (a review in any
  mode advances the single per-language streak, exactly as today).

## Carried-forward note from Story 002 review (MUST address here)
After Story 002, the quiz views call `recordSnapshot(cards: cardStore.allCards, …)` where `cardStore`
is now the *active mode's* store — so the aggregate `(day, language, quizMode=="")` snapshot is
overwritten with only one mode's counts and the persisted daily history under-counts the cross-mode
aggregate. This story MUST fix that: the aggregate snapshot recording must use the cross-mode union
(e.g. `provider.allCards`) — or accumulate — so the aggregate reflects all modes, AND additionally
write a per-mode `(day, language, quizMode)` snapshot for the grading mode. Call sites:
`MapQuizView`, `MultipleChoiceQuizView`, `CapitalQuizView`, `NameFeatureQuizView`.

## Acceptance Criteria
- [ ] `DailyProgressSnapshot` rows exist both per-mode (`quizMode == "<mode>"`) and as the aggregated
      rollup (`quizMode == ""`); dedup keys on `(day, language, quizMode)`.
- [ ] The aggregated rollup equals the sum across modes and matches the pre-feature default numbers
      (verified by a test recording in two modes and asserting the aggregate).
- [ ] A graded answer in a mode updates that mode's per-mode snapshot and the aggregate; other modes'
      per-mode snapshots are untouched.
- [ ] The per-language streak still advances on a review in ANY mode (shared, not per-mode) —
      regression-guarded by a test.
- [ ] `just build` and `just test` green, including new per-mode snapshot tests.
