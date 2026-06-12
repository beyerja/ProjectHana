# Story 013: evaluate-workflow — Phase 2b Before/After Telemetry Meta-Evaluation

## Goal

Extend `evaluate-workflow.md` with a Phase 2b block that compares telemetry from before and after previous agent edits, checks whether previously recommended changes were actually applied via git history, and assesses whether the qualitative findings from those evaluations held up.

## Acceptance Criteria

- [ ] After Phase 2a output, `evaluate-workflow.md` contains a clearly labelled "Phase 2b — Meta-Evaluation" section.
- [ ] When fewer than two prior workflow runs exist in telemetry, Phase 2b is skipped and a note is logged: "Skipping Phase 2b — insufficient telemetry (fewer than 2 prior runs)."
- [ ] The agent checks git log on `.claude/agents/` files to determine which files were edited since the last evaluation run, and which recommended edits (from that run's commit messages) were not applied.
- [ ] For each applied edit the agent uses the git commit timestamp as the before/after boundary, then compares `.workflow/telemetry/agents-*.jsonl` and `hooks-*.jsonl` records on each side of that boundary. It reports per-agent changes in: token counts, retry counts, and durations (improved / flat / regressed).
- [ ] Previously recommended edits that are NOT reflected in git history are flagged as "not applied" (not automatically treated as bloat candidates).
- [ ] Qualitative findings are retrieved from git commit messages on `.claude/agents/` changes; the agent assesses whether subsequent telemetry supports or contradicts each finding and states its conclusion inline.
- [ ] The final output separates Phase 1, Phase 2a, and Phase 2b sections with clear headings.
- [ ] No file edits of any kind are made during Phase 2b — it is read-only analysis.
- [ ] This story depends on Story 012 (Phase 2a must be in the file first so the section ordering is correct).

## Target File

`.claude/agents/evaluate-workflow.md` — this is the only file modified by this story.
