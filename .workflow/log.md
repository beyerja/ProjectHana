# Workflow Log

2026-06-11 evaluate-workflow: DONE
Telemetry outliers: implement-story (highest avg tokens ~4,500; long wall-clock run on 001-learning-phase-model with no end record — session likely exceeded context); Edit tool dominated at ~225k tokens across 64 calls
Improvements:
  1. implement-story.md — added SwiftData schema change section: wipe simulator store before tests, audit existing tests for broken field assumptions, use in-memory ModelConfiguration in tests
  2. break-tasks.md — added rule: if story modifies @Model, always add an explicit task to audit existing tests for the changed type immediately after the model task
  3. verify-story.md — added simulator boot + app uninstall step before test run when story touched @Model, preventing stale-schema crash
2026-06-11T21:45:06Z clarify-feature: DONE
2026-06-11T21:45:06Z break-stories: DONE, 2 stories
2026-06-11T22:31:17Z evaluate-workflow: DONE
Telemetry outliers: implement-story (orphaned start record for 001-learning-phase-model — context overflow, no end); evaluate-workflow (highest avg tokens ~6k across 4 runs, driven by reading all agent files on every invocation)
Improvements:
  1. implement-story.md — added pre-extension grep rule: check for existing extensions/computed properties on a type before adding new ones to prevent "invalid redeclaration" compile errors (e.g. displayName on CardCategory)
  2. break-tasks.md — added extension collision check: when a task adds presentation helpers to an existing type, prepend an audit task to grep existing extensions first
  3. evaluate-workflow.md — added orphaned-start detection: flag start records with no matching end as likely context-overflow sessions and exclude them from averages
