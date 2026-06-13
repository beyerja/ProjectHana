# Workflow Log

## i18n: French, German, Spanish support

2026-06-12T07:43:42Z orchestrator: START — feature = i18n (French, German, Mexican Spanish + fallback, English)
2026-06-12T21:33:30Z evaluate-workflow: DONE
Telemetry outliers: evaluate-workflow (highest avg tokens: 8 083; orphaned start on current run), story-workflow (all 5 i18n runs orphaned — no end records logged)
Phase 2a flags: evaluate-workflow (134 lines, >5 rule sections) — proposed simplification declined; length is load-bearing
Phase 2b: 3 distinct workflow dates present. All prior recommendations applied. implement-story before/after: Insufficient data (i18n runs all orphaned). evaluate-workflow avg tokens trended up (2 000 → 11 250) as Phase 2a/2b sections were added — expected given feature additions.
Improvements: (1) story-workflow — clarified that just log end must be run by the orchestrating agent itself, not delegated; (2) wait-for-ci — added story-id derivation instruction so telemetry does not log "unknown"; (3) evaluate-workflow — removed hooks token estimates (est_chars is 0 in this project); simplified hooks report to call counts only
