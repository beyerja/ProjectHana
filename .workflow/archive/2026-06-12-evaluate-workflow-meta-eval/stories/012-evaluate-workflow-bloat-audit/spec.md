# Story 012: evaluate-workflow — Phase 2a Agent Bloat Audit

## Goal

Extend `evaluate-workflow.md` with a Phase 2a block that audits every agent file in `.claude/agents/` for bloat using three structural heuristics, then presents a proposed trimmed version inline and asks the user to confirm before any edit is made. No automatic rewrites are ever performed.

## Acceptance Criteria

- [ ] After the existing Phase 1 output, `evaluate-workflow.md` contains a clearly labelled "Phase 2a — Agent Bloat Audit" section.
- [ ] The audit reads all files in `.claude/agents/` and flags any file that meets one or more of these thresholds:
  - Line count > 80 lines
  - `description` front-matter field longer than 2 sentences
  - More than 5 distinct rules or numbered sections
- [ ] For each flagged file the agent outputs:
  1. The current full file content (clearly labelled)
  2. A proposed trimmed version (clearly labelled)
  3. The explicit prompt: "Apply this simplification? (confirm to proceed)"
- [ ] No `Edit` call is made until the user responds affirmatively — the agent waits for confirmation.
- [ ] Files that pass all three heuristics are listed as "OK" with no proposed changes.
- [ ] The Phase 2a section is self-contained: it does not depend on git history or telemetry data, only on the current file content.
- [ ] Telemetry `end` call and `.workflow/log.md` append happen after both phases complete (not after Phase 1 alone).

## Target File

`.claude/agents/evaluate-workflow.md` — this is the only file modified by this story.
