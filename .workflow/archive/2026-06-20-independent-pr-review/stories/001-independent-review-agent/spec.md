# 001 — Create `independent-review` agent and retire `review-pr`

## Title
Create the `independent-review` agent (cold-context, self-PR-safe) and retire `review-pr`

## Goal
Add a new `.claude/agents/independent-review.md` agent that performs a 4-eye, cold-context
review of an already-opened PR using the existing `/code-review` skill, handles the GitHub
self-review constraint by emitting its verdict via STATUS output, and drives a bounded
feedback loop. Retire the old human-centric `review-pr` agent in the same change.

This story delivers the agent in isolation. It does NOT wire the agent into `story-workflow`
(that is story 002). The agent file is self-contained and the workflow continues to function
without it until 002 lands, so this commit compiles/operates on its own.

## Acceptance Criteria
- [ ] A new agent file `/Users/Private/Documents/Code/ProjectHana/.claude/agents/independent-review.md`
      exists with `name: independent-review` frontmatter and a description.
- [ ] The agent file states explicitly that it MUST be spawned fresh as a separate, cold-context
      agent invocation and that it MUST NOT be the implementer/author of the PR. It documents that
      independence (the 4-eye principle) is guaranteed by the orchestrator spawning a distinct
      agent invocation — the agent does not self-police authorship beyond refusing if it detects it
      authored the change.
- [ ] The agent reuses the existing `/code-review` skill invoked with `--comment` as the review
      engine, so findings are posted as inline, line-level comments on the PR. It does NOT
      reimplement bespoke review logic.
- [ ] GitHub self-review constraint is handled: the agent MUST NOT run `gh pr review --approve`
      or `gh pr review --request-changes` (GitHub blocks self-approval when the reviewer is the
      same `gh` user that opened the PR). Instead it posts a `COMMENT`-type review plus inline
      comments (both allowed on one's own PR), and carries its verdict via STATUS output:
      `STATUS: APPROVED` or `STATUS: CHANGES_REQUESTED`. The agent file must NOT introduce or
      rely on any formal review-state (APPROVE/REQUEST_CHANGES) gate.
- [ ] The agent posts a summary comment with a stable marker on the PR reflecting the verdict, for
      human visibility.
- [ ] The agent documents the feedback-loop contract it participates in: on
      `CHANGES_REQUESTED`, an implement agent addresses every comment, replies to each thread
      marking it resolved, runs checks, and pushes; then the reviewer is re-spawned. The agent
      notes the loop is capped at 3 rounds before escalating to the user (the cap is enforced by
      the orchestrator in story 002; the agent only emits its per-round verdict).
- [ ] The agent follows CLAUDE.md "Emit allowlistable command shapes" rules (no `cd && …`, no
      heredocs/`$(…)` for text payloads, no poll loops; use `gh -R`, write bodies to files and use
      `--body-file`, etc.) and includes the standard telemetry start/end calls
      (`just log start/end independent-review ...`).
- [ ] The old `/Users/Private/Documents/Code/ProjectHana/.claude/agents/review-pr.md` is removed
      (retired) — its responsibility is superseded by `independent-review`. No remaining agent file
      other than `story-workflow` references `review-pr` (the `story-workflow` reference is
      rewired in story 002).

## Out of Scope
- Wiring the agent into `story-workflow` or `.workflow/README.md` (story 002).
- A separate GitHub bot identity / PAT enabling formal `APPROVE` / `REQUEST_CHANGES` states
  (future enhancement — note in the agent file, do not build).
- CI structure changes.
