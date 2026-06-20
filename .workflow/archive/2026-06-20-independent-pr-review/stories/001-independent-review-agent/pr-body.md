## Goal

Add a new `.claude/agents/independent-review.md` agent that performs a 4-eye, cold-context review of an already-opened PR using the existing `/code-review` skill. It handles the GitHub self-review constraint by emitting its verdict via STATUS output, drives a bounded feedback loop, and retires the old human-centric `review-pr` agent.

This story delivers the agent in isolation. It does NOT wire the agent into `story-workflow` (that is story 002). The agent file is self-contained and the workflow continues to function without it until 002 lands.

## Summary of changes

- Add `.claude/agents/independent-review.md` with `name: independent-review` frontmatter and a description.
- The agent documents that it MUST be spawned fresh as a separate, cold-context invocation and MUST NOT be the PR author; independence (4-eye principle) is guaranteed by the orchestrator spawning a distinct agent, and the agent refuses if it detects it authored the change.
- The agent reuses the existing `/code-review` skill invoked with `--comment` as the review engine, posting findings as inline, line-level comments. It does not reimplement bespoke review logic.
- GitHub self-review constraint handled: the agent does NOT run `gh pr review --approve` / `--request-changes`. It posts a `COMMENT`-type review plus inline comments and carries its verdict via `STATUS: APPROVED` / `STATUS: CHANGES_REQUESTED`. No formal review-state gate is introduced.
- The agent posts a summary comment with a stable marker reflecting the verdict for human visibility.
- The agent documents the feedback-loop contract (address comments, reply/resolve threads, re-run checks, push, re-spawn reviewer), noting the 3-round cap enforced by the orchestrator in story 002.
- The agent follows CLAUDE.md "Emit allowlistable command shapes" rules and includes the standard `just log start/end independent-review ...` telemetry calls.
- Remove (retire) `.claude/agents/review-pr.md`; its responsibility is superseded by `independent-review`. The only remaining reference to `review-pr` is in `story-workflow` (rewired in story 002).

## Test plan

- [ ] `independent-review.md` exists with correct `name:` frontmatter and a description.
- [ ] Agent file states the cold-context / non-author independence requirement and self-author refusal.
- [ ] Agent invokes `/code-review --comment` and does not reimplement review logic.
- [ ] Agent does NOT use `gh pr review --approve`/`--request-changes`; verdict carried via STATUS output.
- [ ] Agent posts a stable-marker summary comment.
- [ ] Feedback-loop contract and 3-round cap documented.
- [ ] CLAUDE.md command-shape rules followed and telemetry start/end calls present.
- [ ] `review-pr.md` removed; only `story-workflow` still references `review-pr`.
