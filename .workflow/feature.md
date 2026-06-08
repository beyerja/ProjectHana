# Feature: Agent Telemetry Logging

## Goal
All agents in the workflow should log timing and token-usage estimates for each run. These logs must not be committed to the repo. The `evaluate-workflow` agent must read the logs at the end of each workflow and use them to identify efficiency opportunities.

## Background and constraints

Claude Code agents cannot query their own API token counts from within a run. The best available proxies are:
- **Wall-clock duration**: `date -u` at start and end of each agent run
- **Content volume**: sum of chars in files read, written, and edited → divide by 4 for approximate tokens
- **Tool call counts**: number of Read, Write, Edit, Bash, and Agent tool invocations

Two complementary logging mechanisms will be used:

1. **Automatic (hook-based)**: A `PostToolUse` hook in `.claude/settings.json` fires after every tool call. The hook script (`scripts/telemetry-hook.sh`) reads the tool use data from stdin and appends a JSONL record to `.workflow/telemetry/`. This captures per-tool granularity without requiring agents to self-report.

2. **Manual (agent boundary)**: A script `scripts/agent-log.sh` is called explicitly by each agent at start and end of its run. This captures the agent name, story context, timestamps, self-reported metrics (tool counts, estimated chars), and qualitative notes (e.g. retries, blockers).

## Log location and gitignore

Logs live in `.workflow/telemetry/` — a directory that exists in the repo (via `.gitkeep`) but whose `*.jsonl` files are gitignored. The scripts themselves are committed.

## JSONL format

**Hook log** (one record per tool call): `.workflow/telemetry/hooks-YYYY-MM-DD.jsonl`
```json
{"ts":"2026-06-08T10:01:23Z","tool":"Read","input_chars":0,"output_chars":4500,"est_tokens":1125}
```

**Agent log** (one start + one end record per agent run): `.workflow/telemetry/agents-YYYY-MM-DD.jsonl`
```json
{"ts":"2026-06-08T10:00:00Z","event":"start","agent":"implement-story","story":"004-sm2-scheduler"}
{"ts":"2026-06-08T10:35:00Z","event":"end","agent":"implement-story","story":"004-sm2-scheduler","duration_s":2100,"reads":12,"writes":3,"edits":8,"bashes":22,"agents_spawned":0,"est_chars":68000,"est_tokens":17000,"retries":1,"notes":"Had to fix compile error on first build"}
```

## Evaluate-workflow integration

At the end of each workflow, `evaluate-workflow` must:
1. Read all JSONL files in `.workflow/telemetry/`
2. Aggregate per-agent: total estimated tokens, total duration, retry count, tool call distribution
3. Identify outliers: agents with unusually high token/time ratios or retry counts
4. Produce a brief analysis table in the workflow log
5. Suggest targeted agent-prompt improvements based on observed patterns

## Acceptance criteria

- After completing a feature workflow, `.workflow/telemetry/` contains non-empty JSONL files
- The JSONL files are NOT tracked by git (`git status` shows nothing in that directory)
- `evaluate-workflow` produces a per-agent efficiency table in its output
- At least one concrete agent improvement is identified from the telemetry data
- All existing agent behavior is preserved (telemetry is additive)
