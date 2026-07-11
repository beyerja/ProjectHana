---
name: story-workflow
description: Orchestrate the full lifecycle of a single user story: task breakdown, implementation, PR, review loop, merge, and verification
---

Requires: story directory path.

**Telemetry — run at the very start (ignore errors):**
```
just log start story-workflow "<story-id>" || true
```

**Autonomous execution — do NOT stop between steps.** After each sub-agent returns, immediately
proceed to the next step in the same session. Never output "I'll wait for it to complete" or pause
for user input mid-lifecycle — the full story lifecycle (break-tasks → implement → PR → CI → review
→ merge → verify) runs in one uninterrupted session. Only stop when a step reaches an explicit
escalation condition (the 3-round review cap, or a CI failure you cannot resolve after one retry).

**Run all sub-agents foreground (never background).** Sub-agents spawned in the background deliver
their completion notification to the main conversation loop, not back to this agent. That breaks the
sequential step chain and causes the lifecycle to stall. **Background is the Agent tool's DEFAULT when
`run_in_background` is omitted** — explicitly pass `run_in_background: false` on **every** Agent call,
and never end your turn while a spawned child is still running (a story this rule previously only
implied stalled exactly that way: helpers were spawned without the flag, the turn ended waiting on
them, and the parent had to finish the relay).

**If a sub-agent returns without a `STATUS:` line**, do not proceed to the next step. The agent may
have spawned a background child that drained its context before completing. Re-read `<story-dir>/log.md`
and live git/gh state to determine the actual outcome, then re-spawn that step's agent foreground if
needed. Never assume a missing STATUS means success.

Run the following steps in order, spawning a dedicated sub-agent for each. Pass the story directory as context to every agent.

**Resume idempotently — trust live state over any briefing.** A run may be re-spawned after an
interruption (foreground session-token limits resume mid-feature), so a story you are handed may already
be partly or fully done. Before acting, **read `<story-dir>/log.md` and the live git/gh state** (branch,
`gh pr list --head story/<slug>/<story-id>`), and treat each step as a skip-if-already-done gate: don't
re-break-tasks if `tasks.md` is complete, don't `create-pr` if a PR is already open (pick up at its
review/merge state), don't re-merge a merged PR. Where the spawning briefing and live state disagree
(e.g. the briefing says "no PR yet" but `gh` shows an open one), **the live git/gh state wins** — the
briefing is a snapshot that may be stale. Record the resume point in `<story-dir>/log.md`.

**Branch-behind resume case.** When a PR is already open but `gh pr view <n> --json mergeStateStatus`
reports `BEHIND` (main advanced while the session was interrupted), bring it current before continuing:
```sh
gh pr update-branch <n> -R <owner/repo>
```
After update-branch, the head SHA changes, so CI must re-run and the `code-owner-review` gate check must
be re-posted on the new SHA. Pick up at step 4 (wait-for-ci) with the updated PR. Even if
`independent-review` already emitted APPROVED before the branch fell behind, the gate check from that
round is SHA-bound to the old head and no longer satisfies the gate — you MUST re-spawn `code-owner-review`
on the updated PR so it posts a fresh check on the new SHA.

**PR-base contract (autonomous, no human gate):** each story PR targets **`main`** directly (not an
intermediate feature branch), so it is CI-gated and goes through the independent-review loop below.
There is no story→feature-branch PR and no human merge click anywhere in this loop — merge is automatic
once the reviewer emits APPROVED and CI is green (step 6). Do NOT pause to wait for a human to review or
merge a story PR.

1. **Break tasks** — spawn `break-tasks` agent
2. **Implement** — spawn `implement-story` agent
3. **Create PR** — spawn `create-pr` agent (skip if a PR for this story branch is already open per the
   resume check above; carry its number forward to step 4)
4. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 3 and the story-id
   - STATUS: FAIL → fix the failure (go to step 2 with CI failure as context), then re-push; repeat from step 4
   - STATUS: PASS → continue
5. **Two-eye review loop** — ordered AFTER CI passes (step 4) so reviewers see code that builds. Two
   distinct, cold-context reviewers form a real 4-eye gate. Both are **separate spawns from the implement
   agent of step 2** — NEVER reuse the implementer or its context to review its own work. Cap the loop at
   **3 rounds**.

   a. **Deep review + verdict** — spawn the `independent-review` agent (fresh, cold). It runs the deep
      `/code-review` pass, posts inline comments + a summary, and emits STATUS. It does **NOT** set the
      formal gate check (invoking the `/code-review` skill ends its turn before it could).
      - STATUS: CHANGES_REQUESTED → spawn an `implement-story` agent (a **separate spawn, never a reviewer**)
        to address **every** inline comment, **reply to each review thread acknowledging the fix** (a reply
        alone does NOT resolve the thread on GitHub), run the project checks (`just lint`, `just test`), and
        push. Then **re-spawn a fresh `independent-review`** on the updated PR. Counts as one round.
      - STATUS: APPROVED → continue to 5b.
   b. **Independent confirm + formal submission** — spawn the `code-owner-review` agent (fresh, cold, and
      distinct from BOTH the implementer and the `independent-review` agent). It re-verifies the diff a
      second time **without** the `/code-review` skill (so its turn completes), reaches its **own** verdict,
      runs the **CI self-heal** (re-trigger if the head has no required checks), and — through the bot
      wrapper `scripts/gh-review-bot.sh` — posts the required **`code-owner-review` status check**
      (conclusion success/failure) on the PR head that gates merge, with app-id read-back proof. When the
      bot credentials are absent (wrapper exits non-zero), the gate check is SKIPPED and the loop proceeds
      on STATUS alone.
      - STATUS: CHANGES_REQUESTED → spawn an `implement-story` agent to address it and push, then go back to
        **5a** (re-spawn `independent-review`). Counts as one round.
      - STATUS: APPROVED (and, when the bot credentials are present, the `code-owner-review` check posted as
        success) → continue to step 6.

   After **3 rounds** without both reviewers reaching APPROVED, **STOP looping and ESCALATE to the user**
   (do not loop further); leave the PR open. (There is no human-review gate: the workflow never pauses for
   the user to review or merge a PR except this 3-round escalation.)
6. **Merge** — once **both** `independent-review` and `code-owner-review` emitted APPROVED **and** CI is
   green, spawn `merge-pr` **unconditionally**. Do not assume the user already merged and do not wait for a
   human merge click.
   **Worktree lifecycle:** `merge-pr` deletes the story *branch* (via `--delete-branch`) but must NOT
   remove or exit the worktree directory — the worktree must remain intact through step 7. When running
   inside a dedicated feature worktree, only the feature-orchestrator's archive step may remove the
   worktree, never story-workflow.
7. **Verify** — spawn `verify-story` agent
   - STATUS: FAILED → go to step 2 (re-implement with failure context)
   - STATUS: DONE → finish

Update `<story-dir>/status.md` at **every** phase boundary, BEFORE spawning the next step's agent — a
current status.md is the resume anchor that makes session-token interruptions recoverable (one run was
interrupted three times mid-story and recovered each time only because status.md matched reality). If
returning to a prior step, note the reason in `<story-dir>/log.md`.

**Telemetry — always run before exiting, even if a subagent handled the final step:**
```
just log end story-workflow "<story-id>" 0 0 0 <B> 0 "" || true
```
Where `<B>` = number of Bash calls made directly by this agent (not by subagents). This call must be issued by the story-workflow agent itself, not delegated.

Output STATUS: DONE when the story is merged and verified.
