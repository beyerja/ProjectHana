# Story 002: Agent Instrumentation and Evaluation Enhancement

## Goal
Instrument every agent in `.claude/agents/` to call `agent-log.sh` at start and end of each run, and update `evaluate-workflow` to read and analyze the telemetry data.

## Tasks

- [ ] Update `implement-story.md` — add start/end `agent-log.sh` calls; instruct agent to count its tool calls (reads, writes, edits, bashes) and estimate chars for the end record
- [ ] Update `break-tasks.md` — same start/end logging
- [ ] Update `create-pr.md` — same start/end logging
- [ ] Update `wait-for-ci.md` — same start/end logging
- [ ] Update `review-pr.md` — same start/end logging
- [ ] Update `merge-pr.md` — same start/end logging
- [ ] Update `verify-story.md` — same start/end logging
- [ ] Update `break-stories.md` — same start/end logging
- [ ] Update `archive-workflow.md` — same start/end logging
- [ ] Update `evaluate-workflow.md` — at start, read all `.workflow/telemetry/*.jsonl` files; aggregate per-agent stats; produce an efficiency table; embed analysis in workflow log output

## Agent logging instruction (add to each agent)

At the very start of an agent's work, run:
```
bash scripts/agent-log.sh start <agent-name> "<story-id-or-context>"
```
Record the current time (note it).

At the very end, before writing the log.md entry, self-count:
- **reads**: number of Read tool calls made
- **writes**: number of Write tool calls made
- **edits**: number of Edit tool calls made  
- **bashes**: number of Bash tool calls made
- **est_chars**: total chars of files read + chars of files written/edited (rough estimate based on file sizes)

Then run:
```
bash scripts/agent-log.sh end <agent-name> "<story-id>" <reads> <writes> <edits> <bashes> <est_chars> "<brief-notes>"
```

## Evaluate-workflow telemetry analysis

After reading story logs (existing behavior), also:
1. Read all files matching `.workflow/telemetry/agents-*.jsonl`
2. For each `end` record, compute: duration (end_ts - matching start_ts), estimated tokens = est_chars / 4
3. Build a Markdown table:
   ```
   | Agent            | Runs | Avg Duration | Avg Est Tokens | Total Retries |
   |------------------|------|-------------|----------------|---------------|
   | implement-story  |  5   |  28 min     |  15 000        |  2            |
   ```
4. Identify the top 1-2 outliers (highest tokens or most retries)
5. Read the hook log (`.workflow/telemetry/hooks-*.jsonl`) if present; report aggregate tool-call distribution
6. Append the table and analysis to the `evaluate-workflow` output

## Acceptance criteria

- After running any instrumented agent, its start+end records appear in `.workflow/telemetry/agents-YYYY-MM-DD.jsonl`
- Running `evaluate-workflow` at end of a workflow that has telemetry data produces a per-agent stats table
- The table identifies at least one agent as an efficiency target (highest tokens/time or highest retries)
- All existing agent behavior is preserved — telemetry calls are additive, failure of `agent-log.sh` must not block agent work (use `|| true`)
