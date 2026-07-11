## Stories

- [x] 000-workflow-lint-tooling: Setup — add actionlint + dependabot.yml schema validation to the lint gate (flake dev shell, `just lint`, lint.yml CI)
- [x] 001-fix-current-failures: Fix the two failing dependency-update automations (Dependabot swift + Update flake.lock)
- [x] 002-failure-monitor-workflow: Add the `dep-update-failure-monitor` workflow that opens/appends a deduplicated failure issue
- [x] 003-workflow-agent-integration: Teach feature-orchestrator and triage-dep-prs to pick up open `dep-update-failure` issues
