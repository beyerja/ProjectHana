2026-06-20T10:51:22Z clarify-feature: DONE (in-place meta run; spec written)
2026-06-20T10:55:00Z break-stories: DONE — 3 stories (allowlist / CLAUDE.md conventions / agent edits)
2026-06-20T10:55:00Z assess-project-health: DONE — none. Tooling present (just lint sh/yaml/nix, CI). Meta run touches only .claude/ config; no setup stories.
2026-06-20T11:03:23Z wait-for-ci: PASS — Lint+gitleaks green, Build&Test skipped (docs-only, build-relevant detector).
2026-06-20T11:03:23Z verify-feature: DONE — before/after pass maps every prompted bucket to an applied shape-fix and/or prepared allow entry; hooks still fire; lint green. Story 001 (allowlist) blocked by Auto-mode self-grant guard — prepared for manual apply.
2026-06-20T11:04:02Z evaluate-workflow: DONE
Telemetry outliers (live, 91 runs/3 dates): implement-story 11 retries (known top signal); verify-feature avg 18m / wait-for-ci 8 notes (CI-wait, expected).
Permission remediation: this run WAS the remediation — applied command-shape conventions (CLAUDE.md + 6 agent files) covering all 6 prompted buckets.
Headline finding: under Auto mode the auto-mode classifier DENIES an agent editing .claude/settings.json (self-granting permission). The single biggest prompt lever (allowlist widening) is therefore a human action, not agent-applicable. Encoded this into evaluate-workflow.md Phase 1b (allowlist edits = propose-and-wait; prefer self-applicable shape fixes).
Phase 2a/2b: no further agent edits — the improvements landed as the feature itself.
