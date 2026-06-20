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

Read all `.workflow/telemetry/hooks-*.jsonl` if present and report call counts per tool type. Each record carries `est_tokens`; when populated, report avg `est_tokens` per tool to find over-reads/over-generates (when all zero, fall back to counts only):
```
Tool call distribution (this workflow):
  Read: NNN   Bash: NNN   Write: NNN   Edit: NNN   Agent: NNN
```

Identify the top 1-2 outliers (highest avg estimated tokens → over-reads/over-generates; most retries or non-empty notes → ambiguous instructions or scope too large). Then read all `.claude/agents/` files in one parallel batch, pick up to 3 concrete high-impact improvements, and apply them as targeted, surgical edits (no rewrites).

## Phase 1b — Permission-prompt remediation

Goal: cut the permission prompts the user has to approve, using the capture from the `PreToolUse` permission-capture hook.

Read this run's `.workflow/telemetry/permissions-<date>.jsonl` (today's date; the file is local-only and gitignored). Each line is `{ts, tool, command, signature}`, where `signature` is the leading executable + first subcommand (e.g. `git status`, `gh pr`) so repeats group. **If the file is absent or empty, output `Permission capture: none this run — skipping remediation.` and skip the rest of this sub-phase** (graceful no-op: no error, no edits). Analyze only the current run's capture — never retroactively allowlist past runs.

**Filter inspection noise first.** The capture also catches one-off inspection commands from the verify-feature step and from evaluate-workflow's own reads (`cat`, `ls`, `grep`, `git diff`/`show`, `sleep`, and multi-line/compound `echo "===" && …` script blocks). For compound or multi-line commands the `signature` degrades to a meaningless leading token (`echo "===`, `cd …`, `for f`, `sleep 8;`) — these are not recurring workflow commands and must NOT be allowlisted. Only consider a signature for remediation when it is a clean recurring *workflow build/PR* command (a repeated `just`/`git`/`gh`/`xcodebuild` invocation the agents actually rely on). If every captured signature is inspection noise, output `Permission capture: NN records, all inspection noise — no recurring workflow command to allowlist.` and skip the rest of this sub-phase.

Group the remaining records by `signature`, count frequency, and show the distribution in the report so the user sees what drove each recommendation:
```
Prompted-command distribution (this run):
  <signature>: NN
  <signature>: NN
```

For each frequently-prompted signature, decide a remedy and classify it against the **security bar**:

- **Auto-apply** — only when the command is *deterministic and side-effect-bounded* (read-only-ish; no destruction, no network, no privilege change). Remedy: add a named `just` recipe wrapping it plus a single **non-injectable** `Bash(just <recipe> *)` allow entry, **or** add an agent instruction to prefer an existing safe recipe. Apply it within the same run (edit the `justfile` and/or `.claude/settings.json` and/or the relevant agent file), and report each applied remedy.
- **Propose-and-wait** — when the command *or allowlisting it* could be a security concern: destructive (rm/mv/overwrite outside scratch), network-fetching, privilege-changing, or wildcard-injectable (a `*` in the allow pattern could match arbitrary shell). Output the proposal and make **NO** edit until the user confirms — mirroring the Phase 2a bloat-audit behavior.

**Security bar (hard rule):** never auto-add a broad or injectable allow pattern. The only allow form you may auto-add is a single `Bash(just <recipe> *)` whose recipe wraps one fixed command. When in doubt, propose — do not edit.

**Under "Auto" permission mode, editing `.claude/settings.json` is blocked entirely** (self-granting
permission is intent-resistant and the classifier denies it). So treat *any* allowlist edit as
**Propose-and-wait** — surface the exact entries for the user to add by hand. The remedy an agent *can*
self-apply is the command **shape**: prefer an existing safe `just` recipe, or fix the agent instruction
to emit an allowlistable form per CLAUDE.md → "Emit allowlistable command shapes" (path-flags not `cd`,
`commit -F`/`--body-file` not heredocs, `--watch` not poll loops). Reach for shape fixes first; propose
settings edits second.

## Phase 2a — Agent bloat audit

Read every `.claude/agents/` file and look for **genuine bloat** — content that could be cut without losing information: rules that restate each other, examples that merely repeat the rule they follow, hedging/filler prose, or a description longer than 2 sentences.

Raw size is **not** bloat. A long file, or one with many sections, that is all necessary, non-redundant, project-specific guardrails — each preventing a distinct real failure (e.g. "don't hand-edit the generated pbxproj", the SwiftData stale-store wipe, `just`-only env) — is fine. Do not flag a file on line count or section count alone; mark it `✓ <filename> — OK`, optionally noting `(long but each rule earns its place)`.

- No removable content: `✓ <filename> — OK`.
- Genuine bloat found: output `⚠ <filename> — <what is redundant/removable>`, then a proposed trimmed version (same intent, shorter — merge the redundant rules, cut the restating examples, description to 1 sentence), then `Apply this simplification? (no edit without explicit approval)`.

Do **not** Edit any agent file in Phase 2a. Output proposals and wait; apply on confirmation in a follow-up turn.

## Phase 2b — Meta-evaluation

This phase needs cross-run history. The live `.workflow/telemetry/` holds only the current run, but every prior run's telemetry is preserved in its committed archive under `.workflow/archive/*/telemetry/agents-*.jsonl`. Run `just telemetry-history` to get the combined per-agent summary over **live + archived** telemetry (it prints the distinct-date count and lists the dates).

**Skip if** that combined live + archived set (`.workflow/telemetry/agents-*.jsonl` plus `.workflow/archive/*/telemetry/agents-*.jsonl`) has fewer than 2 distinct workflow dates: output `Skipping Phase 2b — insufficient telemetry (fewer than 2 prior runs).` and stop.

1. **Applied-edit detection** — run `git log --oneline --follow -- .claude/agents/ | head -20`. Identify files modified since the last evaluation. Flag any file recommended in a prior evaluation commit but never subsequently modified: `⚠ <filename>: previous recommendation not applied`.
2. **Before/after telemetry** — read end-records from the combined live + archived set above; for each edited file, use its commit timestamp as the boundary and compare per-agent `avg_duration_min`, `avg_est_tokens`, `retry_count`: **Improved** (>10% better), **Flat** (±10%), **Regressed** (>10% worse), or **Insufficient data** (<2 records on a side). Never fabricate a trend.
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
Permission remediation: <"none this run" or "distribution: <sig:count, …>; applied: <…>; proposed: <…>">
Phase 2a flags: <flagged files or "none">
Phase 2b: <"skipped" or summary>
Improvements: <list>
```

Output STATUS: DONE with a brief summary of what changed and why.
