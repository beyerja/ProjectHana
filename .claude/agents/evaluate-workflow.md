---
name: evaluate-workflow
description: Analyze the completed workflow execution and improve agent files in .claude/agents/ based on observed inefficiencies
---

**Telemetry — run at the very start (ignore errors):**
```
bash scripts/agent-log.sh start evaluate-workflow "feature" || true
```

Read `.workflow/log.md` and every `<story-dir>/log.md`.

## Telemetry analysis

Read all files matching `.workflow/telemetry/agents-*.jsonl` if any exist. If no telemetry files are found, or if fewer than 2 agent end-records are present (e.g. the first workflow after instrumentation was added), note this and proceed with qualitative analysis from story logs alone — do not block.

For files that exist, parse JSONL line by line. Match `"event":"start"` records with their `"event":"end"` counterparts by (agent, story). Build this Markdown table and print it in your output:

```
| Agent                  | Runs | Avg Duration | Avg Est Tokens | Total Retries/Notes |
|------------------------|------|-------------|----------------|---------------------|
| implement-story        |  N   |  XX min     |  XX 000        |  N                  |
| break-tasks            |  N   |  XX min     |  XX 000        |  N                  |
| ...                    |      |             |                |                     |
```

Where:
- **Avg Duration** = mean of `duration_s` across end records for that agent, converted to minutes
- **Avg Est Tokens** = mean of `est_tokens` across end records (est_chars / 4)
- **Total Retries/Notes** = count of end records where `notes` is non-empty

Also read all `.workflow/telemetry/hooks-*.jsonl` if present. Aggregate by tool type (Read, Write, Edit, Bash, Agent) and report total call counts and total estimated tokens per tool type:

```
Tool call distribution (this workflow):
  Read:   NNN calls,  ~XX k tokens
  Bash:   NNN calls,  ~XX k tokens
  Write:  NNN calls,  ~XX k tokens
  Edit:   NNN calls,  ~XX k tokens
```

Note: Edit token estimates are inflated when large files are involved (pbxproj, bundled JSON data) because the hook measures the full file content, not the diff. If Edit est_tokens is unexpectedly high (> 50k), identify the likely large-file culprit and discount that figure when assessing true agent cost.

## Qualitative analysis

Based on the telemetry table and story logs, identify the top 1-2 outliers:
- Highest avg estimated tokens → its prompt likely over-reads or over-generates
- Most retries/non-empty notes → its instructions are ambiguous or its scope is too large

## Agent improvements

Read all files in `.claude/agents/`.

Identify up to 3 concrete, high-impact improvements informed by the telemetry and story logs. For each: edit the relevant agent file directly with the improvement. Prefer targeted, surgical changes over rewrites.

## Finish

Run (ignore errors):
```
bash scripts/agent-log.sh end evaluate-workflow "feature" <R> <W> <E> <B> <est_chars> "" || true
```

Append to `.workflow/log.md`:
```
<timestamp> evaluate-workflow: DONE
Telemetry outliers: <agents>
Improvements: <list>
```

Output STATUS: DONE with a brief summary of what changed and why.
