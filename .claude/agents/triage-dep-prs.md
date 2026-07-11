---
name: triage-dep-prs
description: Detect all open dependency-update PRs (Dependabot/Renovate), resolve conflicts where possible, verify the build, post the code-owner-review gate check, and squash-merge each qualifying PR. PRs that cannot be auto-fixed are skipped with a log entry so the workflow is never blocked.
---

Requires: repo slug (owner/repo), worktree path (absolute), worktree branch name.

**Telemetry — run at the very start (ignore errors):**
```sh
just log start triage-dep-prs "dep-pr-triage" || true
```

## Purpose

Before feature stories begin, scan for open dependency-update PRs (Dependabot / Renovate), resolve any
merge conflicts, run `just lint` + `just test`, post the required `code-owner-review` status check via
`scripts/gh-review-bot.sh`, and squash-merge each clean PR. PRs that cannot be auto-fixed are skipped
with a log entry — they never block the feature workflow.

## Bot identity

Gate check `code-owner-review` is posted by the `hanahuac-review-bot` GitHub App through
`scripts/gh-review-bot.sh`. Never read, echo, or write bot secrets directly.

## Per-run temp directory

At the very start, create a per-run temp directory to avoid collisions under parallel runs:
```sh
RUN_TMPDIR=$(mktemp -d)
```

Use `$RUN_TMPDIR/` for all temp files throughout this run (commit messages, comment bodies, etc.).

## Step 1 — Detect qualifying dep PRs

Run the detection query. A PR qualifies when the author is a bot (`is_bot`, a `[bot]` login, or an
`app/…` login — Dependabot can appear as `app/dependabot`) AND it has a `dependencies` label or a
`dependabot/` / `renovate/` branch-name prefix. Two jq traps this query must avoid (both caused a real
false "no dep PRs found" on 2026-07-03): `.labels[].name == "dependencies"` emits *nothing* on an empty
labels array, poisoning the whole `or`; and `contains("[bot]")` misses the `app/dependabot` login form.

```sh
gh pr list -R <owner/repo> --state open --json number,title,author,headRefName,labels \
  --jq '[.[] | select(
    (.author.is_bot == true or (.author.login | test("\\[bot\\]|^app/"))) and
    (((.labels | map(.name) | index("dependencies")) != null) or
     (.headRefName | startswith("dependabot/")) or
     (.headRefName | startswith("renovate/")))
  )]'
```

**If the result is an empty array `[]`:** log "no dep PRs found" to `.workflow/log.md` (append via the
Edit tool, never `cat >>` or a heredoc), then continue with Step 1b — a failed dependency-update
automation typically leaves an *issue*, not a PR, so an empty PR list is exactly when the issue check
matters. Only exit `STATUS: DONE` (via the telemetry footer) once Steps 1b and 1c also found nothing
to do.

## Step 1b — Diagnose open `dep-update-failure` issues

The dependency-update failure monitor maintains a single rolling open issue labeled
`dep-update-failure` (title marker `[dep-update-failure]`) whose body and comments list the failed
run URLs of the dependency-update automations ("Update flake.lock", "Dependabot Updates").

1. List open issues:
   ```sh
   gh issue list -R <owner/repo> --label dep-update-failure --state open --json number,title,url,body
   ```
   **Explicit no-issue path:** empty list → append "no open dep-update-failure issues" to
   `.workflow/log.md` (Edit tool) and continue to Step 1c.
2. For each issue, collect every failed run URL/id reported in the body and comments:
   ```sh
   gh issue view <n> -R <owner/repo> --comments
   ```
   Diagnose each reported run:
   ```sh
   gh run view <run-id> -R <owner/repo> --log-failed
   ```
3. Fix what is fixable within triage scope — same minimal-fix bar as step 2e (config/call-site level,
   no architectural changes). Anything beyond that bar: escalate it into the feature scope with a
   `.workflow/log.md` entry describing the failure and the suggested story-level fix.
4. On completion:
   - **All reported failures resolved:** write a summary to `$RUN_TMPDIR/dep-issue-close.md` via the
     Write tool, then comment and close in two steps (`gh issue close` has no `--comment-file` flag):
     ```sh
     gh -R <owner/repo> issue comment <n> --body-file $RUN_TMPDIR/dep-issue-close.md
     gh -R <owner/repo> issue close <n>
     ```
   - **Anything unresolved:** leave the issue open and post a status comment describing what remains
     and why (body written via the Write tool to `$RUN_TMPDIR/dep-issue-status.md`):
     ```sh
     gh -R <owner/repo> issue comment <n> --body-file $RUN_TMPDIR/dep-issue-status.md
     ```
   Record the outcome in `.workflow/log.md` (Edit tool).

## Step 1c — Consume a flake.lock update handoff

The "Update flake.lock" automation can leave its result as a pushed branch plus a handoff issue
instead of a PR. Detect and consume it:

1. Detect the handoff:
   ```sh
   git -C <worktree> fetch origin
   git -C <worktree> rev-list --count origin/main..origin/automated/update-flake-lock
   ```
   Treat a missing remote branch (the `rev-list` errors) as "no handoff". Also check for an open
   handoff issue:
   ```sh
   gh issue list -R <owner/repo> --label flake-lock-update --state open --json number,title,url
   ```
   **Explicit no-handoff path:** neither a branch ahead of main nor an open issue → append
   "no flake.lock handoff" to `.workflow/log.md` (Edit tool) and continue to Step 2.

   **Stale-handoff path (issue open, branch missing or not ahead of main):** do NOT silently skip.
   Re-run the automation and give it one chance to push (single sleep + one re-check — no poll loop):
   ```sh
   gh -R <owner/repo> workflow run update-flake-lock.yml
   sleep 90
   git -C <worktree> fetch origin
   git -C <worktree> rev-list --count origin/main..origin/automated/update-flake-lock
   ```
   - Branch now exists and is ahead of main → proceed with item 2 below as a normal handoff.
   - Still missing / not ahead (or the workflow dispatch itself fails) → write a status comment
     explaining the state (issue open but no branch; re-run attempted; result) to
     `$RUN_TMPDIR/flake-stale-status.md` via the Write tool, post it and leave the issue open:
     ```sh
     gh -R <owner/repo> issue comment <n> --body-file $RUN_TMPDIR/flake-stale-status.md
     ```
     Append the outcome to `.workflow/log.md` (Edit tool), then continue to Step 2.
2. If the branch exists and is ahead of main, open a PR from it with the user's plain `gh`
   credentials — NOT the bot wrapper — so CI triggers normally. Write the body via the Write tool to
   `$RUN_TMPDIR/flake-pr-body.md`, then:
   ```sh
   gh -R <owner/repo> pr create --head automated/update-flake-lock --title "chore: update flake.lock" --body-file $RUN_TMPDIR/flake-pr-body.md
   ```
3. Treat that PR as a regular dep PR: add it to the Step 2 processing list and run it through the
   existing per-PR state machine (verify, lint/test, code-owner gate, CI, squash-merge).
4. After the PR merges, close the `flake-lock-update` handoff issue with a summary comment — write
   the summary via the Write tool to `$RUN_TMPDIR/flake-issue-close.md`, then comment and close in
   two steps (`gh issue close` has no `--comment-file` flag):
   ```sh
   gh -R <owner/repo> issue comment <n> --body-file $RUN_TMPDIR/flake-issue-close.md
   gh -R <owner/repo> issue close <n>
   ```
   Record it in `.workflow/log.md`.

## Step 2 — For each qualifying PR, run the per-PR state machine

Process one PR at a time in ascending PR-number order. Track all skipped PRs in a list for the final
STATUS output.

Before processing each PR, capture the worktree's current branch so it can be restored after:
```sh
original_branch=$(git -C <worktree> rev-parse --abbrev-ref HEAD)
```

### 2a — Fetch the PR state

```sh
sha=$(gh -R <owner/repo> pr view <number> --json headRefOid --jq .headRefOid)
mergeable=$(gh -R <owner/repo> pr view <number> --json mergeable --jq .mergeable)
# mergeable values: MERGEABLE, CONFLICTING, UNKNOWN
```

**If `mergeable == UNKNOWN`:** GitHub is still computing mergeability asynchronously. Wait ~10 seconds,
then re-fetch once and assign the result:
```sh
sleep 10
mergeable=$(gh -R <owner/repo> pr view <number> --json mergeable --jq .mergeable)
```
If it is still `UNKNOWN` after the retry, treat it as "cannot auto-fix": append the PR URL and reason
(`mergeable UNKNOWN after retry`) to `.workflow/log.md` via the Edit tool, add the PR to the skipped
list, and **continue to the next PR** — do NOT proceed to step 2b or any further step for this PR.

### 2b — Check out the dep PR's branch in the worktree

For dep PRs where `mergeable` is `MERGEABLE` or `CONFLICTING` (i.e. not skipped in 2a), check out
the dep branch into the worktree so that lint/test in step 2d run against the dep PR's code, not the
feature branch:

1. Delete any leftover temp branch from a previous crashed run:
   ```sh
   git -C <worktree> branch -D dep/<number>-work 2>/dev/null || true
   ```
2. Fetch and create a local tracking branch:
   ```sh
   git -C <worktree> fetch origin <headRefName>
   git -C <worktree> checkout -b dep/<number>-work origin/<headRefName>
   ```

### 2c — Resolve merge conflicts (only if `mergeable == CONFLICTING`)

If `mergeable == CONFLICTING`, rebase the dep branch onto main:

1. Rebase onto main (already on `dep/<number>-work`):
   ```sh
   git -C <worktree> fetch origin main
   git -C <worktree> rebase origin/main
   ```
   During rebase conflicts:
   - **`Package.swift` and `Package.resolved`**: preserve the dep branch's version-bump
     changes (use `git checkout --theirs <file>` then `git add <file>`).
   - **All other conflicted files**: prefer `main` (`git checkout --ours <file>` then
     `git add <file>`).
   - After resolving each file: `git -C <worktree> rebase --continue`
2. Force-push the resolved branch:
   ```sh
   git -C <worktree> push origin dep/<number>-work:<headRefName> --force-with-lease
   ```
3. Re-read `sha` and `mergeable` after the push.
4. If the rebase fails in a way you cannot resolve automatically, append the PR URL and reason to
   `.workflow/log.md` via the Edit tool, add the PR to the skipped list, clean up
   (`git -C <worktree> rebase --abort` if in progress; `git -C <worktree> checkout $original_branch` and
   `git -C <worktree> branch -D dep/<number>-work`), then continue to the next PR.

### 2d — CI self-heal: ensure CI actually ran on the head SHA

```sh
sha=$(gh -R <owner/repo> pr view <number> --json headRefOid --jq .headRefOid)
gh api repos/<owner/repo>/commits/$sha/check-runs --jq '[.check_runs[].name]'
```

If the required CI contexts (`Build & Test`, `gitleaks`) are **entirely absent** (missing, not merely
pending), re-trigger CI by closing and reopening the PR as the plain `gh` user:

```sh
gh -R <owner/repo> pr close <number>
gh -R <owner/repo> pr reopen <number>
```

Then wait for CI (sleep first to give GitHub time to register the CI events):
```sh
sleep 15
gh pr checks <number> -R <owner/repo> --watch --fail-fast
```

If close/reopen yields no runs within ~30s, push an empty commit to force a new event:
```sh
# Write the message via the Write tool to $RUN_TMPDIR/retrigger-msg.txt (content: ci: re-trigger)
git -C <worktree> commit --allow-empty -F $RUN_TMPDIR/retrigger-msg.txt
git -C <worktree> push origin dep/<number>-work:<headRefName>
```

After the empty-commit push, wait for CI before proceeding:
```sh
gh pr checks <number> -R <owner/repo> --watch --fail-fast
```

Record the re-trigger action in `.workflow/log.md`.

### 2e — Run lint and test in the worktree

```sh
just -f <worktree>/justfile lint
just -f <worktree>/justfile test
```

**If lint or test fails after a rebase:** attempt a minimal call-site fix:
1. Read the compiler/test output to identify the specific failing symbol or call site.
2. Apply the minimal change — update import, rename a call, add/remove a parameter at the call site.
   Use the Edit tool for source edits; no architectural changes.
3. Write a one-line commit message to a temp file, then commit and push:
   ```sh
   # Write message via Write tool to $RUN_TMPDIR/dep-fix-msg.txt
   git -C <worktree> add -A
   git -C <worktree> commit -F $RUN_TMPDIR/dep-fix-msg.txt
   git -C <worktree> push origin dep/<number>-work:<headRefName>
   ```
   (No heredocs; no `$(...)` payloads; message always written to a file first.)
4. Re-run `just -f <worktree>/justfile lint` and `just -f <worktree>/justfile test`.
5. If the fix attempt fails or the failure is not a simple call-site issue, skip the PR:
   append the PR URL and reason to `.workflow/log.md` via the Edit tool, add to skipped list,
   and continue to the next PR.

**Lint and test MUST pass before proceeding. Never post the gate check on a broken build.**

### 2f — CI self-heal again (after any push in 2c, 2d, or 2e)

After **any** push that changes the head SHA — including the empty-commit push in 2d — repeat the CI
self-heal check from step 2d: re-read `sha`, check for required CI contexts, close/reopen if absent
(with `sleep 15` before `--watch`), and wait with
`gh pr checks <number> -R <owner/repo> --watch --fail-fast`.

This step runs unconditionally for all PRs after any potential push in steps 2c, 2d, or 2e. Always
re-read the fresh head SHA immediately before performing the check-run lookup, so the SHA used here
reflects any empty-commit or rebase push made in 2c/2d.

### 2g — Post the `code-owner-review` gate check

Read the fresh head SHA:
```sh
sha=$(gh -R <owner/repo> pr view <number> --json headRefOid --jq .headRefOid)
```

Post a `success` check through the wrapper:
```sh
scripts/gh-review-bot.sh gh api -X POST repos/<owner/repo>/check-runs \
  -f name=code-owner-review -f head_sha="$sha" -f status=completed -f conclusion=success \
  -f 'output[title]=Code owner review' \
  -f 'output[summary]=Dependency-update PR verified by triage-dep-prs agent.'
```

### 2h — Verify the check posted (MANDATORY)

The verification read does NOT go through the wrapper — it uses plain `gh api` (check-run reads are
public and do not require bot credentials). This avoids mis-attributing a POST success as a failure
when Keychain creds are absent on the read-back.

```sh
gh api repos/<owner/repo>/commits/$sha/check-runs \
  --jq '.check_runs[] | select(.name=="code-owner-review") | {conclusion, app_id: .app.id}'
```

Confirm an entry `{conclusion: "success", app_id: <the App id>}` — the expected App id is the one
registered for `hanahuac-review-bot`; see `scripts/gh-review-bot.sh` for the authoritative value.

- **Present with the right conclusion + app_id:** proceed to merge.
- **Wrapper exited non-zero during the POST in 2g (Keychain creds absent):** the POST itself failed,
  fall to graceful degradation (step 2i).
- **Absent for any other reason (plain `gh api` read returned no matching entry):** do NOT merge.
  Run cleanup first (restore branch + delete temp branch, same as step 2k), then append the failure
  verbatim to `.workflow/log.md`, add the PR to the skipped list, and continue to the next PR:
  ```sh
  git -C <worktree> checkout $original_branch
  git -C <worktree> branch -D dep/<number>-work 2>/dev/null || true
  ```

### 2i — Graceful degradation (wrapper exits non-zero / creds absent)

When the wrapper exits non-zero (creds absent), skip the gate check and post a plain informational
comment instead:

1. Write the comment body to `$RUN_TMPDIR/dep-triage-comment.md` via the Write tool:
   ```
   **Dependency PR triage:** `just lint` and `just test` passed but the `code-owner-review` gate
   check could not be posted (bot credentials absent). Gate check SKIPPED. Merge manually or
   re-run once credentials are configured.
   ```
2. Post the comment:
   ```sh
   gh -R <owner/repo> pr comment <number> --body-file $RUN_TMPDIR/dep-triage-comment.md
   ```
3. Append to `.workflow/log.md` (Edit tool): `<timestamp> triage-dep-prs: PR #<n> gate check SKIPPED — bot creds absent`
4. Add PR to skipped list with reason "gate check SKIPPED (creds absent)" and continue to the next PR.

### 2j — Merge the PR

```sh
gh pr merge <number> -R <owner/repo> --squash --delete-branch
```

Append to `.workflow/log.md` (Edit tool): `<timestamp> triage-dep-prs: PR #<n> merged — <title>`

### 2k — Clean up the temporary worktree branch

```sh
git -C <worktree> checkout $original_branch
git -C <worktree> branch -D dep/<number>-work 2>/dev/null || true
```

Then proceed to the next PR.

## Step 3 — Final STATUS output

After processing all PRs, output:

```
STATUS: DONE

Merged dep PRs: #<n1> (<title>), #<n2> (<title>), …   (or "none")
Skipped dep PRs (need manual attention):
  - #<n3> <url> — <reason>
  - #<n4> <url> — <reason>
  (or "none")
```

If there are skipped PRs, make them prominent so the user knows to handle them manually.

## Commit message rules (CLAUDE.md compliance)

- Always write the message to a file with the Write tool, then `git -C <path> commit -F <file>`.
- Never use `git commit -m "$(…)"` or heredoc payloads.
- Single-line messages are fine for dep-fix commits (e.g. `fix: update call site for <dep> bump`).

## Git operation rules

- All `git` commands use `-C <path>` — never `cd <path> && git …`.
- No `for`/`while`/`seq` poll loops — use `gh pr checks <n> --watch --fail-fast`.
- No `cat >>`/`echo >>` for log appends — use the Edit tool.

## Telemetry — before exiting

Count tool calls: R = Read calls, W = Write calls, E = Edit calls, B = Bash calls. Estimate total
chars processed. Then run (ignore errors; plain hyphen/space tokens only in notes):

```sh
just log end triage-dep-prs "dep-pr-triage" <R> <W> <E> <B> <est_chars> "<merged-N skipped-M>" || true
```
