---
name: evaluate-workflow
description: Analyze the completed workflow and make surgical improvements to agent files in .claude/agents/
---

**Telemetry — run at the very start (ignore errors):**
```
just log start evaluate-workflow "feature" || true
```

Read `.workflow/log.md` and every `<story-dir>/log.md`.

## Phase 1 — Telemetry analysis & improvements

Run `just telemetry` for the agent summary table. If it reports no telemetry, note that and proceed qualitatively from story logs — do not block.

Read all `.workflow/telemetry/hooks-*.jsonl` if present and report call counts per tool type (`est_chars` is 0 in this project, so skip token estimates from hooks — use counts only):
```
Tool call distribution (this workflow):
  Read: NNN   Bash: NNN   Write: NNN   Edit: NNN   Agent: NNN
```

Identify the top 1-2 outliers (highest avg estimated tokens → over-reads/over-generates; most retries or non-empty notes → ambiguous instructions or scope too large). Then read all `.claude/agents/` files in one parallel batch, pick up to 3 concrete high-impact improvements, and apply them as targeted, surgical edits (no rewrites).

## Phase 2a — Agent bloat audit

Read every `.claude/agents/` file and look for **genuine bloat** — content that could be cut without losing information: rules that restate each other, examples that merely repeat the rule they follow, hedging/filler prose, or a description longer than 2 sentences.

Raw size is **not** bloat. A long file, or one with many sections, that is all necessary, non-redundant, project-specific guardrails — each preventing a distinct real failure (e.g. "don't hand-edit the generated pbxproj", the SwiftData stale-store wipe, `just`-only env) — is fine. Do not flag a file on line count or section count alone; mark it `✓ <filename> — OK`, optionally noting `(long but each rule earns its place)`.

- No removable content: `✓ <filename> — OK`.
- Genuine bloat found: output `⚠ <filename> — <what is redundant/removable>`, then a proposed trimmed version (same intent, shorter — merge the redundant rules, cut the restating examples, description to 1 sentence), then `Apply this simplification? (no edit without explicit approval)`.

Do **not** Edit any agent file in Phase 2a. Output proposals and wait; apply on confirmation in a follow-up turn.

## Phase 2b — Meta-evaluation

**Skip if** `.workflow/telemetry/agents-*.jsonl` has fewer than 2 distinct workflow dates: output `Skipping Phase 2b — insufficient telemetry (fewer than 2 prior runs).` and stop.

1. **Applied-edit detection** — run `git log --oneline --follow -- .claude/agents/ | head -20`. Identify files modified since the last evaluation. Flag any file recommended in a prior evaluation commit but never subsequently modified: `⚠ <filename>: previous recommendation not applied`.
2. **Before/after telemetry** — for each edited file, use its commit timestamp as the boundary and compare per-agent `avg_duration_min`, `avg_est_tokens`, `retry_count`: **Improved** (>10% better), **Flat** (±10%), **Regressed** (>10% worse), or **Insufficient data** (<2 records on a side). Never fabricate a trend.
3. **Qualitative finding accuracy** — for each "why" line in prior evaluation commits, state the original claim, check whether the relevant telemetry moved as predicted, and output **Supported**, **Contradicted**, or **Inconclusive** with one sentence of evidence.

## Finish

Run (ignore errors):
```
just log end evaluate-workflow "feature" <R> <W> <E> <B> <est_chars> "" || true
```

Append to `.workflow/log.md`:
```
<timestamp> evaluate-workflow: DONE
Telemetry outliers: <agents>
Phase 2a flags: <flagged files or "none">
Phase 2b: <"skipped" or summary>
Improvements: <list>
```

Output STATUS: DONE with a brief summary of what changed and why.
