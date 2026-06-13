# Story 001: just telemetry recipe

## Goal

Add a `just telemetry` recipe that parses `.workflow/telemetry/agents-*.jsonl`
and prints a summary table to stdout, so agents can call it instead of
duplicating inline JSONL parsing shell commands.

## Acceptance Criteria

- [ ] `just telemetry` is defined in `justfile`.
- [ ] Running `just telemetry` with no JSONL files present prints an empty table
  or a "no telemetry found" message and exits 0 (graceful, not an error).
- [ ] Running `just telemetry` with one or more `agents-*.jsonl` files present
  prints a Markdown table with columns: Agent, Runs, Avg Duration (min), Avg
  Est Tokens, Total Retries/Notes.
- [ ] The recipe is accompanied by a brief comment in `justfile` describing its
  purpose.
- [ ] The recipe works with the top-level `export PATH` and `export DEVELOPER_DIR`
  already set in the justfile (no extra PATH setup needed inside the recipe).
