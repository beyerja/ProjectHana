# Tasks — Story 001: Telemetry Infrastructure

- [ ] Create `scripts/telemetry-hook.sh` — PostToolUse hook; reads stdin JSON; appends JSONL to `.workflow/telemetry/hooks-YYYY-MM-DD.jsonl`
- [ ] Create `scripts/agent-log.sh` — start/end boundary marker; appends JSONL to `.workflow/telemetry/agents-YYYY-MM-DD.jsonl`
- [ ] Create `.workflow/telemetry/.gitkeep`
- [ ] Update `.gitignore` — add `.workflow/telemetry/*.jsonl`
- [ ] Update `.claude/settings.json` — add PostToolUse hook + allow list entry for the hook script
