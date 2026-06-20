## Goal

Rewire `story-workflow` step 5 to spawn the `independent-review` agent (from story 001) AFTER CI passes, key the workflow off the reviewer's STATUS output, run a bounded feedback loop, and proceed to merge autonomously once the reviewer emits `APPROVED` and CI is green. Update `.workflow/README.md` so the documented step sequence matches, and remove the old human-review gate (`PENDING_REVIEW` / "wait for the user to merge" path).

## Summary of changes

- `story-workflow.md` step 5 now spawns the `independent-review` agent (a fresh, cold-context invocation distinct from the implement agent), ordered AFTER the CI-pass step (step 4) so it reviews code that builds.
- Review loop keys off the reviewer's STATUS output:
  - `STATUS: CHANGES_REQUESTED` → spawn an implement agent to address every inline comment, reply to each thread marking it resolved, run checks, push; then re-spawn `independent-review`. Capped at **3 rounds**; after 3 rounds without `APPROVED`, escalate to the user.
  - `STATUS: APPROVED` → continue.
- Removed the old human-review gate: no more `PENDING_REVIEW` branch and no step that waits for the user to review/merge. Once `APPROVED` AND CI is green, the workflow merges autonomously (spawns `merge-pr`; no human merge click).
- Removed all references to the retired `review-pr` agent from `story-workflow.md`.
- Updated `.workflow/README.md` step sequence: independent review after CI passes, bounded (3-round) feedback loop, autonomous merge on APPROVED + green CI, no human review/merge gate; `review-pr` mentions replaced with `independent-review`.
- Step 6 (Merge) no longer assumes "the user already merged"; spawns `merge-pr` unconditionally once APPROVED + CI green.
- Telemetry and the closing `STATUS: DONE` behavior of `story-workflow` are intact.

## Test plan

- [ ] `story-workflow.md` step 5 spawns `independent-review` and is ordered after step 4 (CI pass).
- [ ] Review loop branches on `CHANGES_REQUESTED` / `APPROVED` and is capped at 3 rounds with user escalation.
- [ ] No `PENDING_REVIEW` branch or human review/merge wait remains.
- [ ] No references to `review-pr` remain in `story-workflow.md` or `.workflow/README.md`.
- [ ] `.workflow/README.md` step sequence reflects the new flow and autonomous merge.
- [ ] Telemetry and closing `STATUS: DONE` behavior unchanged.
