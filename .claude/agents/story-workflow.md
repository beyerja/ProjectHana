---
name: story-workflow
description: Orchestrate the full lifecycle of a single user story: task breakdown, implementation, PR, review loop, merge, and verification
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start story-workflow "<story-id>" || true
```

Run the following steps in order, spawning a dedicated sub-agent for each. Pass the story directory as context to every agent.

**PR-base contract (autonomous, no human gate):** each story PR targets **`main`** directly (not an
intermediate feature branch), so it is CI-gated and goes through the independent-review loop below.
There is no story→feature-branch PR and no human merge click anywhere in this loop — merge is automatic
once the reviewer emits APPROVED and CI is green (step 6). Do NOT pause to wait for a human to review or
merge a story PR.

1. **Break tasks** — spawn `break-tasks` agent
2. **Implement** — spawn `implement-story` agent
3. **Create PR** — spawn `create-pr` agent
4. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 3 and the story-id
   - STATUS: FAIL → fix the failure (go to step 2 with CI failure as context), then re-push; repeat from step 4
   - STATUS: PASS → continue
5. **Two-eye review loop** — ordered AFTER CI passes (step 4) so reviewers see code that builds. Two
   distinct, cold-context reviewers form a real 4-eye gate. Both are **separate spawns from the implement
   agent of step 2** — NEVER reuse the implementer or its context to review its own work. Cap the loop at
   **3 rounds**.

   a. **Deep review + verdict** — spawn the `independent-review` agent (fresh, cold). It runs the deep
      `/code-review` pass, posts inline comments + a summary, and emits STATUS. It does **NOT** submit the
      formal bot review (invoking the `/code-review` skill ends its turn before it could).
      - STATUS: CHANGES_REQUESTED → spawn an `implement-story` agent (a **separate spawn, never a reviewer**)
        to address **every** inline comment, **reply to each review thread acknowledging the fix** (a reply
        alone does NOT resolve the thread on GitHub), run the project checks (`just lint`, `just test`), and
        push. Then **re-spawn a fresh `independent-review`** on the updated PR. Counts as one round.
      - STATUS: APPROVED → continue to 5b.
   b. **Independent confirm + formal submission** — spawn the `code-owner-review` agent (fresh, cold, and
      distinct from BOTH the implementer and the `independent-review` agent). It re-verifies the diff a
      second time **without** the `/code-review` skill (so its turn completes), reaches its **own** verdict,
      runs the **CI self-heal** (re-trigger if the head has no required checks), and — through the bot
      wrapper `scripts/gh-review-bot.sh` — submits the formal `Hanahuac-Bot` review state (with read-back
      proof) and resolves addressed bot-authored threads via `resolveReviewThread`. When the bot token is
      absent (wrapper exits non-zero), the formal state + thread resolution are SKIPPED and the loop
      proceeds on STATUS alone.
      - STATUS: CHANGES_REQUESTED → spawn an `implement-story` agent to address it and push, then go back to
        **5a** (re-spawn `independent-review`). Counts as one round.
      - STATUS: APPROVED (and, when the bot token is present, the bot `APPROVE` posted) → continue to step 6.

   After **3 rounds** without both reviewers reaching APPROVED, **STOP looping and ESCALATE to the user**
   (do not loop further); leave the PR open. (There is no human-review gate: the workflow never pauses for
   the user to review or merge a PR except this 3-round escalation.)
6. **Merge** — once **both** `independent-review` and `code-owner-review` emitted APPROVED **and** CI is
   green, spawn `merge-pr` **unconditionally**. Do not assume the user already merged and do not wait for a
   human merge click.
7. **Verify** — spawn `verify-story` agent
   - STATUS: FAILED → go to step 2 (re-implement with failure context)
   - STATUS: DONE → finish

Update `<story-dir>/status.md` at each transition. If returning to a prior step, note the reason in `<story-dir>/log.md`.

**Telemetry — always run before exiting, even if a subagent handled the final step:**
```
just log end story-workflow "<story-id>" 0 0 0 <B> 0 "" || true
```
Where `<B>` = number of Bash calls made directly by this agent (not by subagents). This call must be issued by the story-workflow agent itself, not delegated.

Output STATUS: DONE when the story is merged and verified.
