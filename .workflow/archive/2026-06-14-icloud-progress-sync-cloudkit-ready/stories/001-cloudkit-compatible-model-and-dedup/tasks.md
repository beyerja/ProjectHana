# Tasks — Story 001

- [ ] T1: Give every stored property on `ReviewCard` a model-level default value (CloudKit
  requires optional-or-default); confirm no `@Attribute(.unique)`; add comments explaining
  uniqueness is enforced in app logic.
- [ ] T2: Add `CardStore.deduplicate()` collapsing duplicate `ReviewCard`s by `factID` to one
  canonical card (deterministic, most-progressed winner).
- [ ] T3: Make `seedIfNeeded` insert only the missing factIDs (per-factID idempotent), not the
  all-or-nothing empty-store check.
- [ ] T4: Add unit tests: dedup collapses + preserves most-progressed; re-seed/partial-seed adds
  no duplicates; empty seed gives exactly one card per fact.
- [ ] T5: `just generate` if files added; run build/test; ensure existing tests pass.
