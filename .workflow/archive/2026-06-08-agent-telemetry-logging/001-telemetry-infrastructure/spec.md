# Story 001: Telemetry Infrastructure

## Goal
Create the foundational scripts and configuration that enable automatic tool-call logging and agent boundary markers for the workflow telemetry system.

## Tasks

- [ ] Create `scripts/telemetry-hook.sh` — reads PostToolUse hook payload from stdin, appends a JSONL record to `.workflow/telemetry/hooks-YYYY-MM-DD.jsonl`
- [ ] Create `scripts/agent-log.sh` — called by agents at start/end; appends a JSONL record to `.workflow/telemetry/agents-YYYY-MM-DD.jsonl`
- [ ] Create `.workflow/telemetry/.gitkeep` so the directory exists in the repo
- [ ] Update `.gitignore` — add `.workflow/telemetry/*.jsonl` so log files are never committed
- [ ] Update `.claude/settings.json` — register `scripts/telemetry-hook.sh` as a `PostToolUse` hook; add `Bash(bash scripts/telemetry-hook.sh*)` to the permissions allow list

## Acceptance criteria

- Running `bash scripts/agent-log.sh start test-agent story-001` creates a new JSONL file under `.workflow/telemetry/` with a valid JSON object on one line
- Running `bash scripts/agent-log.sh end test-agent story-001 5 2 3 8 12000 "no issues"` appends an end record with those values
- `git status` after running both scripts shows `.workflow/telemetry/*.jsonl` as untracked but NOT staged (gitignored)
- `.claude/settings.json` contains a `hooks` section with a `PostToolUse` entry pointing to `scripts/telemetry-hook.sh`
- `scripts/telemetry-hook.sh` is executable, reads stdin without error when given an empty or minimal JSON payload

## Notes

The hook payload format (stdin JSON from Claude Code) is expected to contain at minimum: `tool_name` (string). If `input` and `output` fields are present, their string lengths are summed and divided by 4 for `est_tokens`. The script must be defensive — if a field is missing, use 0.

`agent-log.sh` signature:
```
agent-log.sh start  <agent-name> <story-id>
agent-log.sh end    <agent-name> <story-id> <reads> <writes> <edits> <bashes> <est_chars> "<notes>"
```
