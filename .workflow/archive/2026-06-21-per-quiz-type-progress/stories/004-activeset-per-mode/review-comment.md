<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context, high-recall 4-eye review of per-mode active-set namespacing.

**Verdict: APPROVED** — no blocking findings.

### Correctness
- **Key namespacing is right:** `mode != nil` → `activeSet.<language>.<mode>.<category>`; `mode == nil`
  → the legacy per-language `activeSet.<language>.<category>`. The two key spaces can't collide because
  mode tokens (`mapQuiz`/`multipleChoice`/…) are never category rawValues. ✓
- **No call-site breakage / no behavior change for existing callers:** `mode` defaults to `nil`
  everywhere, so the existing per-language `ProgressMigrator` step (`activeSetKey(language:category:)`)
  and all existing ActiveSetStore/sync tests keep hitting the legacy per-language key unchanged. ✓
- **All 3 store impls + both factories + `SyncCoordinator.makeActiveSetStore` thread `mode`**, and the
  4 quiz views each pass their correct mode. ✓
- **Migration source preserved:** `legacyPerLanguageActiveSetKey(language:category:)` exposes the
  pre-per-mode key for Story 005 to copy into the `mapQuiz` per-mode key — test-covered. ✓
- Tests cover namespacing, per-mode isolation on `save`/`clear`, and the legacy migration source.

Ready to merge.
