# Tasks — Story 003: evaluate-workflow analysis & gated remediation

Single-file documentation edit to `.claude/agents/evaluate-workflow.md`. Surgical; match the
existing Phase 1 / Phase 2a / Phase 2b structure and voice.

## Context (from the permission-capture hook, story 002)
- Sink: `.workflow/telemetry/permissions-<date>.jsonl`, one JSON object per line.
- Record shape: `{ "ts", "tool", "command", "signature" }`.
  - `signature` = leading executable + first subcommand (e.g. `git status`, `gh pr`), so repeats
    group naturally. Bash-only records carry `command` + `signature`; non-Bash records carry only
    `tool`.
- File is gitignored, local-only, and may be absent or empty (no captures this run).

## Tasks
1. Add a new telemetry sub-phase (e.g. "Phase 1b — Permission-prompt remediation") to
   `evaluate-workflow.md`, slotted right after the Phase 1 tool-distribution analysis so it reads
   naturally as part of telemetry analysis.
   - Instruct: read the current run's `.workflow/telemetry/permissions-<date>.jsonl`; if absent or
     empty, emit a one-line no-op note and skip the rest of the sub-phase (graceful no-op, no error,
     no edits).
2. Group records by `signature`, count frequency, and render a distribution table
   (signature -> count) in the report so the user sees what drove each recommendation.
3. Define the classification per the security bar:
   - AUTO-APPLY (uncritical): deterministic and side-effect-bounded. Remedy = add a named `just`
     recipe wrapping the command plus a single `Bash(just <recipe> *)` allow entry, OR add an agent
     instruction to prefer an existing safe recipe. Apply within the same run.
   - PROPOSE-AND-WAIT (security-sensitive): destructive (rm/mv/overwrite outside scratch),
     network-fetching, privilege-changing, or wildcard-injectable. Output the proposal; make NO edit
     until the user confirms — mirroring the existing Phase 2a bloat-audit behavior.
4. Encode the security bar explicitly: never auto-add a broad/injectable allow pattern; the only
   auto-added allow form is a single non-injectable `Bash(just <recipe> *)`; when in doubt, propose.
   Only the current run's capture is analyzed (no retroactive allowlisting).
5. Update the Finish block / log append so the new sub-phase's outcome (distribution + applied vs.
   proposed remedies) is recorded, consistent with how Phase 2a/2b results are logged.

## Out of scope
- No app code, no hook changes, no new scripts (recipes are only added at *runtime* by the agent
  when it actually finds a qualifying signature; this story only writes the instructions).
- Capturing/handling non-Bash permission prompts beyond what the sink already records.
