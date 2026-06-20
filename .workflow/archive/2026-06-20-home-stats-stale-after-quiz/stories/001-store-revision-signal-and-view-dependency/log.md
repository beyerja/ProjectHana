# Log — Observable store revision signal + HomeView/StatsView depend on it
2026-06-20 break-tasks: DONE, 7 tasks
2026-06-20 implement-story: DONE — all 7 tasks (CardStore + ProgressStatsStore revision signals, HomeView + StatsView body reads, regression tests), lint + test green, no issues
2026-06-20 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/110
2026-06-20 review-pr: PENDING_REVIEW — awaiting human review
2026-06-20T13:34:04+0200 merge-pr: DONE
2026-06-20 verify-story: DONE — all 7 acceptance criteria satisfied. Both stores expose private(set) var revision (@Observable) bumped via markChanged() after every modelContext.save() path (CardStore: upsert, resetAll, seedIfNeeded, deduplicate, ensureGraduationConsistency; ProgressStatsStore: recordSnapshot, deduplicate). HomeView reads cardStore.revision and StatsView reads cardStore.revision + progressStatsStore?.revision in body before fetch-derived work. .id(languageManager.current) intact in both views. Regression tests assert revision increments on all six required methods. just lint passed; just test SUCCEEDED.
