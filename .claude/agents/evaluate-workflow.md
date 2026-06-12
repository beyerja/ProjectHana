---
name: evaluate-workflow
description: Analyze the completed workflow execution and improve agent files in .claude/agents/ based on observed inefficiencies
---

**Telemetry — run at the very start (ignore errors):**
```
just log start evaluate-workflow "feature" || true
```

Read `.workflow/log.md` and every `<story-dir>/log.md`.

## Phase 1 — Telemetry analysis

Read all files matching `.workflow/telemetry/agents-*.jsonl` if any exist. If no telemetry files are found, or if fewer than 2 agent end-records are present (e.g. the first workflow after instrumentation was added), note this and proceed with qualitative analysis from story logs alone — do not block.

For files that exist, parse JSONL line by line. Match `"event":"start"` records with their `"event":"end"` counterparts by (agent, story). **Note any orphaned start records** (start with no matching end) — these indicate a session that hit a context limit or was interrupted; flag them in the table with "(no end — likely context overflow)" and exclude them from duration/token averages. Build this Markdown table and print it in your output:

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

Based on the telemetry table and story logs, identify the top 1-2 outliers:
- Highest avg estimated tokens → its prompt likely over-reads or over-generates
- Most retries/non-empty notes → its instructions are ambiguous or its scope is too large

Read all files in `.claude/agents/` in a single parallel batch (issue all Read calls at once). Identify up to 3 concrete, high-impact improvements informed by the telemetry and story logs. Edit the relevant agent files directly with each improvement. Prefer targeted, surgical changes over rewrites.

---

## Phase 2a — Agent Bloat Audit

Read every file in `.claude/agents/`. For each file, check all three bloat heuristics:
1. **Line count** > 80 lines
2. **Description** front-matter field longer than 2 sentences
3. **Distinct rules or numbered sections** > 5 (count `##` headings, bold rule paragraphs, and numbered lists at the top level)

For each file that passes all three checks, output a single line: `✓ <filename> — OK`.

For each **flagged** file (fails one or more heuristics), output:

```
⚠ <filename> — flagged: <which heuristics failed>

### Current content
<full current file content>

### Proposed trimmed version
<rewritten version — same intent, shorter: merge redundant rules, cut examples that duplicate the rule itself, shorten description to 1 sentence>

Apply this simplification? (confirm to proceed — no edit will be made without your explicit approval)
```

Do **not** call the Edit tool on any agent file during Phase 2a. Output the proposals and wait. If the user confirms, apply the edit in a follow-up turn.

---

## Phase 2b — Meta-Evaluation

**Skip condition:** If `.workflow/telemetry/agents-*.jsonl` contains fewer than 2 distinct workflow dates (i.e. only one prior run exists), output: `Skipping Phase 2b — insufficient telemetry (fewer than 2 prior runs).` and stop this phase.

### 1. Applied-edit detection

Run:
```sh
git log --oneline --follow -- .claude/agents/ | head -20
```

Identify which agent files were modified since the last evaluation run (use the most recent commit touching `.claude/agents/` before today's evaluation). For each modified file, extract the commit message summary to understand what was recommended and applied.

Flag any agent file that was flagged for improvement in a previous evaluation commit message but shows **no** subsequent modification in git log: output `⚠ <filename>: previous recommendation not applied`.

### 2. Telemetry before/after comparison

For each agent file that WAS edited, use the git commit timestamp as a before/after boundary. Split the telemetry JSONL records into:
- **Before**: records dated before the commit
- **After**: records dated after the commit

Compare per-agent averages for: `avg_duration_min`, `avg_est_tokens`, `retry_count`. Report each as one of:
- **Improved** (after < before by > 10%)
- **Flat** (within 10%)
- **Regressed** (after > before by > 10%)
- **Insufficient data** (fewer than 2 records on either side)

If no records exist on one side, report `Insufficient data` — do not fabricate a trend.

### 2. Qualitative finding accuracy

Retrieve qualitative findings from commit messages on `.claude/agents/` changes (the "why" lines from previous evaluation commits). For each finding:
- State the original claim (e.g. "implement-story retries too much due to ambiguous pbxproj instructions")
- Check subsequent telemetry: did retry counts for that agent go down after the edit?
- Output: **Supported**, **Contradicted**, or **Inconclusive** with one sentence of evidence

---

## Finish

Run (ignore errors):
```
just log end evaluate-workflow "feature" <R> <W> <E> <B> <est_chars> "" || true
```

Append to `.workflow/log.md`:
```
<timestamp> evaluate-workflow: DONE
Telemetry outliers: <agents>
Phase 2a flags: <list of flagged files or "none">
Phase 2b: <"skipped" or summary of before/after findings>
Improvements: <list>
```

Output STATUS: DONE with a brief summary of what changed and why.
