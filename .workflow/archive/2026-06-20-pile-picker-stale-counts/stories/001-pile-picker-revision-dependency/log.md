# Log — PilePickerView counts refresh immediately after a quiz
2026-06-20 break-tasks: DONE, 3 tasks
2026-06-20 implement-story: DONE — tasks 001-003: PilePickerView revision read + regression test; lint and test green, no retries on logic (1 swiftformat redundantThrows fix)
2026-06-20 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/121
2026-06-20 independent-review: APPROVED — exact mirror of #114 HomeView revision pattern; test matches store semantics; no blocking findings
2026-06-20 merge-pr: DONE
2026-06-20 verify-story: DONE — all 4 criteria pass on merged main (6c5d541). C1: PilePickerView.body reads `_ = cardStore.revision` (line 22), mirrors HomeView. C2: counts gated on `> 0` (NavigationLinks), revision read invalidates body after quiz mutation. C3: reuses existing revision/markChanged signal; no CardStore/ProgressStatsStore plumbing or new save paths changed. C4: lint and test both green (TEST SUCCEEDED, incl. new persistCardChanges regression test).
