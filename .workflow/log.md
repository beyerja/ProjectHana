2026-06-14T13:18:59Z clarify-feature: DONE (clarified interactively in main session; Option B — CloudKit-ready, sync disabled)
2026-06-14T13:59:27Z break-stories: DONE, 5 stories
2026-06-14T14:00:31Z assess-project-health: DONE — none (XCTest, CI, Nix flake+direnv all present; no linter by project convention/zero-dep rule)
2026-06-14T14:02:50Z story-workflow 001: DONE (build+test pass; model defaults + dedup-by-factID + per-fact idempotent seed verified)
2026-06-14T14:05:30Z story-workflow 002: DONE (build+test pass; KeyValueStore facade, ubiquitous+local active-set & preference stores, LanguageManager via injected PreferenceStore, local default preserved)
2026-06-14T14:07:40Z story-workflow 003: DONE (build+test pass; SyncFeatureFlag single switch, SyncStatus + availability provider, SyncCoordinator container factory + store selection + sign-out fallback, HanahuacApp delegates; CloudKit gated behind #if CLOUDKIT_SYNC, default OFF, no entitlements added)
2026-06-14T14:10:30Z story-workflow 004: DONE (build+test+build-mac pass; SettingsView with opt-in toggle off-by-default + unavailable handling + status indicator bound to SyncCoordinator; localized en/fr/de/es-MX; SyncStatusPresentation unit-tested)
2026-06-14T14:12:00Z story-workflow 005: DONE (docs only; docs/icloud-sync.md with ordered enable steps + actual file/type names, linked from README; no code/project.yml changes)
