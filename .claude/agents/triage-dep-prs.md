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

Run the detection query. A PR qualifies when the author login contains `[bot]` AND it has a
`dependencies` label or a `dependabot/` / `renovate/` branch-name prefix:

```sh
gh pr list -R <owner/repo> --state open --json number,title,author,headRefName,labels \
  --jq '[.[] | select(
    (.author.login | contains("[bot]")) and
    ((.labels[].name == "dependencies") or
     (.headRefName | startswith("dependabot/")) or
     (.headRefName | startswith("renovate/")))
  )]'
```

**If the result is an empty array `[]`:** log "no dep PRs found" to `.workflow/log.md` (append via the
Edit tool, never `cat >>` or a heredoc), then jump straight to the telemetry footer and exit
`STATUS: DONE`.

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
then re-fetch once:
```sh
gh -R <owner/repo> pr view <number> --json mergeable --jq .mergeable
```
If it is still `UNKNOWN` after the retry, treat it as "cannot auto-fix": append the PR URL and reason
(`mergeable UNKNOWN after retry`) to `.workflow/log.md` via the Edit tool, add the PR to the skipped
list, and continue to the next PR.

### 2b — Check out the dep PR's branch in the worktree

For **all** dep PRs (regardless of `mergeable` status), check out the dep branch into the worktree so
that lint/test in step 2d run against the dep PR's code, not the feature branch:

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

Then wait for CI:
```sh
gh pr checks <number> -R <owner/repo> --watch --fail-fast
```

If close/reopen yields no runs within ~30s, push an empty commit to force a new event:
```sh
git -C <worktree> commit --allow-empty -m "ci: re-trigger"
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

### 2f — CI self-heal again (after any push in 2c or 2e)

After any push that changes the head SHA, repeat the CI self-heal check from step 2d:
re-read `sha`, check for required CI contexts, close/reopen if absent, wait with
`gh pr checks <number> -R <owner/repo> --watch --fail-fast`.

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

```sh
scripts/gh-review-bot.sh gh api repos/<owner/repo>/commits/$sha/check-runs \
  --jq '.check_runs[] | select(.name=="code-owner-review") | {conclusion, app_id: .app.id}'
```

Confirm an entry `{conclusion: "success", app_id: <the App id>}` — the expected App id is the one
registered for `hanahuac-review-bot`; see `scripts/gh-review-bot.sh` for the authoritative value.

- **Present with the right conclusion + app_id:** proceed to merge.
- **Wrapper exited non-zero (Keychain creds absent):** fall to graceful degradation (step 2i).
- **Absent for any other reason:** do NOT merge. Append the failure verbatim to `.workflow/log.md`,
  add the PR to the skipped list, and continue to the next PR.

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
