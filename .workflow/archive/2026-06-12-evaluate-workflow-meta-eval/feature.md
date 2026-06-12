# Feature: evaluate-workflow meta-evaluation pass

## Goal

Extend the existing `evaluate-workflow` agent with a second "meta-evaluation" phase that runs immediately after the normal evaluation phase in the same agent invocation. The meta-evaluation asks: were the findings and edits from the *previous* workflow evaluation actually correct and effective — and are any agent files currently too bloated to maintain?

## Acceptance Criteria

- [ ] The `evaluate-workflow` agent performs its existing first-pass evaluation unchanged, then automatically enters a second meta-evaluation phase in the same run.
- [ ] Meta-evaluation is skipped entirely (with a logged note) when fewer than two prior workflow runs exist in telemetry, because a single run provides insufficient before/after data.
- [ ] The agent detects whether previous edits recommended in the last evaluation were actually applied by checking git history on `.claude/agents/` files.
- [ ] For each applied edit, the agent compares telemetry from runs captured BEFORE the edit (earlier `agents-*.jsonl` / `hooks-*.jsonl` snapshots) versus runs AFTER the edit, and reports whether token counts, retry counts, and durations improved, stayed flat, or regressed.
- [ ] The agent retrieves previous evaluation qualitative findings from git commit messages associated with `.claude/agents/` changes and assesses whether those findings held up against subsequent telemetry data.
- [ ] Agent bloat detection is run as part of the meta-evaluation phase, using these heuristics:
  - Line count > 80 lines
  - `description` field longer than 2 sentences
  - More than 5 distinct rules or sections
- [ ] When bloat is detected, the agent outputs the current file content and a proposed trimmed version inline, followed by an explicit prompt: "Apply this simplification? (confirm to proceed)" — no automatic edits are made.
- [ ] If a previously recommended edit was not applied, the agent flags it (but does not treat it as a bloat candidate automatically).
- [ ] The final output clearly separates Phase 1 (normal evaluation) from Phase 2 (meta-evaluation) findings.

## Constraints

- One agent, one run, two sequential phases — the meta-evaluation is NOT a separate agent or separate invocation.
- The agent must never silently rewrite any file; all proposed changes require explicit user confirmation before any `Edit` call.
- Telemetry source files are `.workflow/telemetry/agents-*.jsonl` and `hooks-*.jsonl`.
- Previous evaluation findings are sourced from git commit messages and git log output on `.claude/agents/` (no separate findings file is assumed to exist).
- Before/after telemetry comparison must use the file modification timestamps (from `git log`) on each agent file as the boundary between "before" and "after" windows.

## Out of Scope

- Automatic application of any simplification or edit without user confirmation.
- Creating a new standalone agent or separate workflow step for meta-evaluation.
- Evaluating agents that have never been edited (no git history on their file) — these can be noted but are not the focus.
- Storing meta-evaluation findings in a separate persistent file (findings live in the agent's output only, unless the normal evaluation workflow already persists results).
- Meta-evaluation of agents outside `.claude/agents/`.
