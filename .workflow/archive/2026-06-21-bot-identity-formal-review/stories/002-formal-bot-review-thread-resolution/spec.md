# 002 — independent-review agent: formal bot review + thread resolution

## Title
Drive `independent-review` to submit a formal bot-authored GitHub review and resolve addressed
threads via `resolveReviewThread`

## Goal
Make the `independent-review` agent submit a REAL GitHub review state (`APPROVE` /
`REQUEST_CHANGES` with inline comments) under the `Hanahuac-Bot` identity through the story-001
wrapper, while preserving its role as the workflow loop driver (still emits `STATUS`) and the
4-eye principle (refuses to review changes it authored). When the implement agent addresses
comments, the corresponding review threads are truly resolved via the `resolveReviewThread`
GraphQL mutation through the wrapper. Degrades gracefully when the Keychain item is absent.

## Scope
- `.claude/agents/independent-review.md` (review submission + thread resolution behavior).
- `.claude/agents/story-workflow.md` where it drives the review loop (consumes STATUS, triggers
  thread resolution after the implement agent addresses comments).

## Depends on
- Story 001 (the `scripts/gh-review-bot.sh` wrapper) — the formal-review and resolve-thread
  calls go through it.

## Acceptance Criteria
- [ ] `independent-review.md` instructs the agent to submit its verdict as a FORMAL GitHub
      review through `scripts/gh-review-bot.sh`: `APPROVE` when clean, `REQUEST_CHANGES` with
      inline comments otherwise (review logic still delegated to the existing `/code-review`
      skill; only the SUBMISSION changes).
- [ ] The agent STILL emits its `STATUS` (`APPROVED` / `CHANGES_REQUESTED`) — formal state is
      additive, not a replacement; `story-workflow.md` continues to branch on STATUS.
- [ ] The 4-eye principle is preserved: the agent refuses (and documents why) if it authored
      the change under review.
- [ ] When the implement agent addresses review comments, `story-workflow.md` /
      `independent-review.md` resolves the corresponding threads via the `resolveReviewThread`
      GraphQL mutation invoked through the bot wrapper — not merely a reply comment. The exact
      mutation/`gh api graphql` invocation shape is specified in the agent doc.
- [ ] Graceful degradation: when the Keychain item `hana-review-bot` is ABSENT (wrapper exits
      non-zero), the agent falls back to a `COMMENT`-type review + `STATUS`, and explicitly
      documents that the formal state and thread resolution were SKIPPED (the loop still
      functions on STATUS alone). The fallback is the documented default until the token is
      provisioned.
- [ ] The agent never prints or reads the token directly; all bot-auth calls go through the
      wrapper.
- [ ] Instructions follow CLAUDE.md command-shape rules (no `cd &&`, no heredocs for payloads;
      review/comment bodies written to a file then passed by `--body-file`/`-F`).

## Notes
- This story changes only agent instruction docs, not Swift app code.
- Keep STATUS as the authoritative loop signal so the workflow is not coupled to the token
  being present.
