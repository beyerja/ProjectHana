<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context, high-recall 4-eye review of per-mode + aggregate daily snapshot recording.

**Verdict: APPROVED** — no blocking findings.

### Correctness
- **The #125 follow-up is fixed:** the new `recordSnapshot(allCards:modeCards:mode:streak:)` upserts the
  aggregate `""` row from the **cross-mode union** (`allCards`) and a per-mode row from `modeCards`, so
  the aggregate snapshot no longer gets overwritten by a single mode. All 7 quiz-view call sites pass
  `cardStoreProvider.allCards` + `cardStore.allCards` + the mode token. ✓
- **Dedup/canonical correctly scoped:** `canonicalSnapshot(for:quizMode:)` filters by mode, and
  `deduplicate` groups by a `(day, quizMode)` key over all rows — so collapsing one mode's dupes never
  touches another mode or the aggregate, and the aggregate `""` row and a per-mode row for the same day
  are not duplicates. ✓
- **Default view unchanged:** `allSnapshots` / `snapshots(since:)` still return only the aggregate
  rows, so the Progress chart's default is byte-identical. ✓
- **Streak untouched** — per-language and shared; regression-guarded by a test. ✓
- Test coverage is thorough (aggregate = all modes, per-mode independence, coexistence, idempotency,
  shared streak).

### Cross-story note recorded into Story 005's spec (not a finding here)
Story 005's migration must stamp only legacy **`ReviewCard`** rows with `mapQuiz` — it must **leave
legacy `DailyProgressSnapshot` rows at `quizMode == ""`**, because after this PR the empty-`quizMode`
snapshot is the mode-aggregated rollup the default chart reads; stamping legacy snapshots `mapQuiz`
would empty the default history. I've updated `005-migration-legacy-to-mapquiz/spec.md` accordingly.

Ready to merge.
