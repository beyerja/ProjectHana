## Goal

Make the `independent-review` agent submit a REAL GitHub review state (`APPROVE` / `REQUEST_CHANGES` with inline comments) under the `Hanahuac-Bot` identity through the story-001 wrapper (`scripts/gh-review-bot.sh`), while preserving its role as the workflow loop driver (still emits `STATUS`) and the 4-eye principle. When the implement agent addresses comments, the corresponding review threads are truly resolved via the `resolveReviewThread` GraphQL mutation through the wrapper. Degrades gracefully when the Keychain item is absent.

This is a docs-only story: it modifies agent instruction files, not Swift app code.

## Changes

- `.claude/agents/independent-review.md` — formal bot review submission (`APPROVE`/`REQUEST_CHANGES` via the wrapper), thread resolution via `resolveReviewThread`, and graceful `COMMENT`-fallback when the token is absent.
- `.claude/agents/story-workflow.md` — drives the review loop: consumes `STATUS`, triggers thread resolution after the implement agent addresses comments.

## Test plan

- [ ] `independent-review.md` instructs submitting the verdict as a FORMAL GitHub review through `scripts/gh-review-bot.sh` (`APPROVE` clean / `REQUEST_CHANGES` with inline comments); review logic still delegated to `/code-review`, only SUBMISSION changes.
- [ ] The agent STILL emits `STATUS` (`APPROVED` / `CHANGES_REQUESTED`); formal state is additive, and `story-workflow.md` continues to branch on STATUS.
- [ ] The 4-eye principle is preserved: the agent refuses (and documents why) if it authored the change under review.
- [ ] Addressed comments resolve threads via the `resolveReviewThread` GraphQL mutation through the bot wrapper (not a reply comment); the exact `gh api graphql` invocation shape is specified in the agent doc.
- [ ] Graceful degradation: when Keychain item `hana-review-bot` is ABSENT (wrapper exits non-zero), the agent falls back to a `COMMENT`-type review + `STATUS` and documents that formal state and thread resolution were SKIPPED.
- [ ] The agent never prints or reads the token directly; all bot-auth calls go through the wrapper.
- [ ] Instructions follow CLAUDE.md command-shape rules (no `cd &&`, no heredocs for payloads; bodies written to a file then passed via `--body-file`/`-F`).
