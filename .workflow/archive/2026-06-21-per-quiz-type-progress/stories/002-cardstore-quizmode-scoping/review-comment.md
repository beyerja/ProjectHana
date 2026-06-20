<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context, high-recall 4-eye review of the per-mode `CardStore` scoping + `CardStoreProvider`.

**Verdict: APPROVED** — no blocking findings.

### Correctness
- **Per-mode scoping is complete and consistent:** every `CardStore` fetch predicate, `seedIfNeeded`,
  `upsert`, `deduplicate`, and `resetAll` now filters/stamps `(language, quizMode)`. Because each store
  is mode-scoped, the dedup `groupBy(factID)` correctly keys on the full identity. ✓
- **Provider invalidation works:** `revision` reads each cached child `CardStore.revision` (an
  `@Observable` property), so a view reading `provider.revision` in its `body` registers a dependency
  on every child — Home pills refresh after a graded answer in any mode. Verified live: the clean-store
  launch renders independent per-mode "New 197" counts. ✓
- **`typeCapital` Countries-only** is enforced by `servedCategories` at seed time and test-covered. ✓
- **No call-site breakage:** the `store(for:)` (HomeQuizMode) vs `store(forModeID:)` (QuizModeID) split
  resolves the `.case`-literal ambiguity cleanly; all view call sites compile and CI is green.

### One tracked follow-up (non-blocking — explicitly deferred to Story 003)
- `cardStore.allCards` now returns only the **active mode's** cards (was the whole language's). The
  unchanged `recordSnapshot(cards: cardStore.allCards, …)` call sites in `MapQuizView` (~L104),
  `MultipleChoiceQuizView` (~L147), `CapitalQuizView`, and `NameFeatureQuizView` therefore upsert the
  `(day, language, quizMode=="")` aggregate **daily snapshot** with a single mode's counts — so the
  *persisted* daily history will under-count the true cross-mode aggregate between now and Story 003.
  The **live** Progress totals stay correct (StatsView reads `provider.allCards`). The PR body calls
  this out and Story 003 reworks snapshot recording (per-mode rows + a true aggregate). **Action for
  Story 003:** pass `provider.allCards` (or accumulate) at these call sites so the aggregate snapshot
  stops being overwritten by one mode. (Couldn't anchor this as an inline comment — the call lines are
  unchanged context, not part of the diff.)

Ready to merge.
