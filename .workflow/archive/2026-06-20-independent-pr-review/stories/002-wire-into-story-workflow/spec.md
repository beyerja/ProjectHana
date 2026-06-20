# 002 — Wire `independent-review` into `story-workflow` and update orchestration docs

## Title
Replace the human-review gate with the `independent-review` step in `story-workflow` and docs

## Goal
Rewire `story-workflow` step 5 to spawn the `independent-review` agent (from story 001) AFTER
CI passes, key the workflow off the reviewer's STATUS output, run a bounded feedback loop, and
proceed to merge autonomously once the reviewer emits `APPROVED` and CI is green. Update
`.workflow/README.md` so the documented step sequence matches. Remove the old human-review
gate (`PENDING_REVIEW` / "wait for the user to merge" path).

This story depends on the `independent-review` agent existing (story 001 ships it as a
self-contained file), so ordering 001 before 002 keeps every commit operable: after 001 the
agent exists but is unreferenced by the workflow; 002 then wires it in.

## Acceptance Criteria
- [ ] `/Users/Private/Documents/Code/ProjectHana/.claude/agents/story-workflow.md` step 5 spawns
      the `independent-review` agent (a fresh, cold-context invocation distinct from the
      implement agent) and is ordered AFTER the CI-pass step (step 4) — review code that builds.
- [ ] The review loop keys off the reviewer's STATUS output:
      - `STATUS: CHANGES_REQUESTED` → spawn an implement agent to address every inline comment,
        reply to each thread marking it resolved, run checks, push; then re-spawn
        `independent-review`. The loop is capped at **3 rounds**; after 3 rounds without
        `APPROVED`, escalate to the user instead of looping further.
      - `STATUS: APPROVED` → continue.
- [ ] The old human-review gate is removed: there is no longer a `PENDING_REVIEW` branch and no
      step that waits for the user to review/merge. Once the reviewer emits `APPROVED` AND CI is
      green, the workflow proceeds to merge **autonomously** (spawn `merge-pr`; no human merge
      click required).
- [ ] `story-workflow.md` no longer references the retired `review-pr` agent anywhere.
- [ ] `/Users/Private/Documents/Code/ProjectHana/.workflow/README.md` is updated so its
      documented step sequence reflects the new flow: independent review runs after CI passes,
      the bounded (3-round) feedback loop, autonomous merge on APPROVED + green CI, and no human
      review/merge gate. Any mention of `review-pr` in the README is replaced with
      `independent-review`.
- [ ] The autonomous-merge change is consistent across the file: step 6 (Merge) no longer assumes
      "the user already merged"; it spawns `merge-pr` unconditionally once APPROVED + CI green.
- [ ] Telemetry and the closing STATUS: DONE behavior of `story-workflow` remain intact.

## Out of Scope
- Creating the `independent-review` agent or retiring `review-pr` (story 001).
- A separate GitHub bot identity / PAT for formal `APPROVE` states (future enhancement).
- CI structure changes.
