# Feature: Independent agent PR review step (4-eye principle)

## Goal
Add a workflow step so that, once a PR is opened, a freshly spawned **independent** agent
(cold context, never the implementer) reviews the diff and leaves comments on GitHub. Its
verdict drives a feedback loop: the comments go back to the implementing agents to address,
push, and re-review — until the reviewer is satisfied. This **replaces** the current
human-review gate in the workflow (`review-pr`'s "wait for the user to merge" path).

## Acceptance Criteria
- [ ] A new dedicated agent (e.g. `independent-review`) reviews PRs and is guaranteed a
      different / cold context from the implementer (4-eye principle) — the author never
      reviews its own change.
- [ ] The reviewer reuses the existing `/code-review` skill (with `--comment`) as the review
      engine to post **inline, line-level** comments on the PR.
- [ ] GitHub self-review constraint handled: because the reviewer authenticates as the same
      `gh` user that opened the PR, it CANNOT submit `APPROVE` / `REQUEST_CHANGES`. Instead it
      posts a `COMMENT`-type review + inline comments (both allowed on one's own PR) and emits
      its verdict via **STATUS output** (`STATUS: CHANGES_REQUESTED` / `STATUS: APPROVED`).
      The workflow loop keys off that STATUS; a summary-comment marker reflects the verdict for
      human visibility.
- [ ] On `CHANGES_REQUESTED`: an implement agent addresses every comment, replies to each
      thread marking it resolved, runs checks, and pushes; the reviewer re-reviews. Loop until
      `APPROVED`, **capped at 3 rounds**, then escalate to the user.
- [ ] The independent review **replaces** the human-review gate: `story-workflow` step 5 no
      longer waits for the user. Once the reviewer emits `APPROVED` **and** CI is green, the
      workflow proceeds to merge **autonomously** (no human merge click).
- [ ] `story-workflow` and the orchestration docs (`.workflow/README.md`) are updated to wire
      the new step in **after CI passes** (review code that builds).
- [ ] The old human-centric `review-pr` is replaced/retired in favor of the new
      `independent-review` agent.

## Constraints
- **Meta-feature** — it modifies workflow tooling (`.claude/agents/`, `.workflow/README.md`,
  possibly telemetry in `justfile`/`scripts/`). Per the orchestrator's Step 0 guard, run in the
  **PRIMARY checkout on a feature branch — NO worktree** (a worktree would carry stale committed
  agent copies).
- Reuse the existing `/code-review` skill rather than writing bespoke review logic.
- The reviewer must run on cold / independent context (a separate agent invocation from the
  implementer).
- Loop cap of **3** review rounds before escalating to the user.
- Follow CLAUDE.md "Emit allowlistable command shapes" rules throughout.

## Out of Scope
- Setting up a separate GitHub bot identity / PAT so the reviewer can submit formal
  `APPROVE` / `REQUEST_CHANGES` review states. (Possible future enhancement; note it, don't
  build it.)
- Changes to CI structure.
