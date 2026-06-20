<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context, high-recall 4-eye review of the one-time legacy→mapQuiz migration.

**Verdict: APPROVED** — no blocking findings.

### Correctness
- **Ordering is right:** per-language step runs before per-mode in `migrateIfNeeded`; the per-mode
  active-set copy reads `legacyPerLanguageActiveSetKey` (= `activeSet.<lang>.<cat>`), exactly what the
  per-language step just wrote. Both steps run before `CardStoreProvider.seedAllModes()` (ordered in
  `AppRootView`), so the mapQuiz store inherits migrated cards instead of re-seeding. ✓
- **Idempotent:** independent `quizModeVersionKey` flag; `stampCardsWithMapQuizMode` only touches
  empty-`quizMode` cards; active-set copy only when the target key is absent. A re-run (incl. a card
  later graded in another mode) is a no-op — test-covered. ✓
- **Snapshots correctly left aggregate (`""`):** matches the Story-003 review note — the default
  Progress chart's history is preserved rather than emptied into a per-mode bucket. ✓
- **CloudKit-safe:** the version flag is per-device `UserDefaults`; a device that synced
  already-stamped mapQuiz cards only stamps its own empty-`quizMode` rows, so no double-stamping. ✓
- **Existing-test audit done right:** `testMigratesLegacyActiveSet…` was updated to assert the new
  end-state — the legacy active set now lands in the `mapQuiz` per-mode key (the per-language key is an
  intermediate the per-mode step consumes). This is the correct product behavior (legacy progress IS
  the Map Tab Quiz), not a regression. The per-language migration remains idempotent.
- Strong test coverage (cards→mapQuiz, snapshots stay aggregate, active set→mapQuiz, idempotency,
  fresh-install no-op).

Ready to merge.
