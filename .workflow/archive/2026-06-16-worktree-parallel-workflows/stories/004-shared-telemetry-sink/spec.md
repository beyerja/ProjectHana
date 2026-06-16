# Story 004 — Shared telemetry sink with per-worktree tagging

## Goal
Ensure all worktrees write telemetry to ONE sink in the primary checkout (not a per-worktree copy),
with each record tagged by feature slug / worktree id, so `telemetry`, `telemetry-history`, and
`evaluate-workflow` Phase 2b aggregate across parallel and historical runs correctly.

## Acceptance Criteria
- [ ] `scripts/agent-log.sh` (via `just log`) resolves the telemetry sink to the primary checkout's
      `.workflow/telemetry/`, even when invoked from a worktree.
- [ ] Each telemetry record is tagged with a feature slug / worktree id.
- [ ] `scripts/telemetry-summary.py` (`just telemetry` / `telemetry-history`) reads the shared sink
      and still produces a correct summary; per-feature attribution is preserved/available.
- [ ] `evaluate-workflow` Phase 2b cross-run aggregation continues to work against the shared sink.
- [ ] Single-checkout behavior is unchanged (sink resolves to its own `.workflow/telemetry/`).
- [ ] `just lint-sh` still passes.
