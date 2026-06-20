# Tasks — 002 Wire `independent-review` into `story-workflow`

- [x] Rewrite `story-workflow.md` step 5 to spawn a fresh, cold-context `independent-review` agent
      (distinct from the implement agent) after the CI-pass step, keying the bounded 3-round loop off
      the reviewer's STATUS (CHANGES_REQUESTED → implement + re-spawn; APPROVED → continue; escalate
      after 3 rounds). Remove the `PENDING_REVIEW` / human-review gate.
- [x] Rewrite `story-workflow.md` step 6 to spawn `merge-pr` unconditionally once APPROVED + CI green.
- [x] Confirm `story-workflow.md` no longer references `review-pr`.
- [x] Update `.workflow/README.md` to document the new per-story lifecycle (independent review after CI,
      bounded 3-round loop, autonomous merge on APPROVED + green CI, no human review/merge gate).
- [x] Verify zero `review-pr` references remain in agent files; run `just lint`.
