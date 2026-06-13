# Story 004: Update agent files to reference just recipes

## Goal

Update `evaluate-workflow.md`, `verify-story.md`, and `verify-feature.md` in
`.claude/agents/` to call the new just recipes instead of duplicating inline
shell commands, so agent instructions stay concise and consistent.

## Acceptance Criteria

- [ ] `evaluate-workflow.md` Phase 1 telemetry analysis section is updated to
  reference `just telemetry` (or note that it is available) instead of
  describing inline JSONL shell parsing. The agent should call `just telemetry`
  to get the summary table as a starting point for its analysis.
- [ ] `verify-story.md` Visual Verification section steps 1-4 are updated to
  use `just boot-sim`, `just install-sim` (which covers build + install),
  `just launch-sim`, and `just screenshot-sim <path>` respectively, replacing
  the inline `xcodebuild` and `xcrun simctl` commands.
- [ ] `verify-feature.md` Visual Verification section steps 1-4 are updated in
  the same way as `verify-story.md`.
- [ ] No acceptance criteria logic or behavior changes in any of the three agent
  files — only the command invocations in the simulator/telemetry steps change.
- [ ] The updated agent files still pass a basic read/lint check (valid Markdown
  with correct front-matter).

## Notes

This story depends on stories 001, 002, and 003 being complete (the recipes
must exist before the agent files reference them). However it can be developed
and merged in the same PR if the recipes are ready.
