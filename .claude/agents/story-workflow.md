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

1. **Break tasks** — spawn `break-tasks` agent
2. **Implement** — spawn `implement-story` agent
3. **Create PR** — spawn `create-pr` agent
4. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 3 and the story-id
   - STATUS: FAIL → fix the failure (go to step 2 with CI failure as context), then re-push; repeat from step 4
   - STATUS: PASS → continue
5. **Independent review loop** — ordered AFTER CI passes (step 4) so the reviewer sees code that builds.
   Spawn the `independent-review` agent as a **fresh, cold-context invocation** that is **explicitly
   distinct from the implement agent** of step 2: the reviewer and the implementer are **separate spawns**,
   so the change is reviewed by someone who did not write it (the 4-eye principle). NEVER reuse the
   implement agent — or its context — to review its own work. The reviewer reads the PR diff cold.

   Key the loop off the reviewer's STATUS output, capped at **3 rounds**:
   - STATUS: CHANGES_REQUESTED → spawn an `implement-story` (implement) agent — again a **separate spawn,
     never the reviewer** — to address **every** inline comment, **reply to each review thread marking it
     resolved**, run the project checks (`just lint`, `just test`), and push the fixes. Then **re-spawn a
     fresh `independent-review`** (cold again) on the updated PR. This counts as one round.
   - STATUS: APPROVED → continue to step 6.

   After **3 rounds** without reaching APPROVED, **STOP looping and ESCALATE to the user** (do not loop
   further); leave the PR open for the user to decide.

   (There is no human-review gate: the workflow never pauses for the user to review or merge a PR. The
   only human touch-point in this loop is the 3-round escalation above.)
6. **Merge** — once the reviewer emitted APPROVED **and** CI is green, spawn `merge-pr` **unconditionally**.
   Do not assume the user already merged and do not wait for a human merge click.
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
