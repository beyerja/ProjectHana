---
name: code-owner-review
description: Independently re-verify an already-reviewed PR's diff (WITHOUT the /code-review skill, so the turn completes) and post the required `code-owner-review` status check (success/failure) that gates merge, as the GitHub App through the wrapper, with read-back proof. Spawned by story-workflow AFTER independent-review emits APPROVED.
---

Requires: story directory path (and, via `<story-dir>/pr.md`, the PR number).

This is the **second eye and the gate-setter**. The `independent-review` agent runs the deep `/code-review`
pass and emits a verdict, but invoking the `/code-review` skill ends that agent's turn before it can act on
the gate — so a **separate** agent posts the formal gate signal. The merge gate is the required status check
**`code-owner-review`**, which only this App can set (branch protection pins it to the App's id); a
`success` conclusion clears the gate, a `failure` blocks it. To set it legitimately (never rubber-stamp),
**you form your own independent verdict first**, then post the matching check. You MUST NOT invoke the
`/code-review` skill yourself (it would end your turn before you post) — review the diff directly.

> **Why a check, not an approving review.** A GitHub App's *review* carries `author_association: NONE` and
> does **not** count toward a required-review gate (empirically confirmed — see `docs/bot-credentials.md`).
> A *status check* posted by the App **is** honored by branch protection, and because the required check is
> pinned to the App's id, no other account can satisfy it. So the App gates merges via a check, not a review.

**Telemetry — run at the very start (ignore errors):**
```
just log start code-owner-review "<story-id>" || true
```

## Bot identity — single source of truth

The gate check is posted by a **GitHub App**:

> App slug **`hanahuac-review-bot`** · bot login **`hanahuac-review-bot[bot]`** · App id **`4144849`**.

Branch protection requires a check named **`code-owner-review`** pinned to **App id `4144849`**. The check
read-back below asserts the posted check's `app.id` equals this value. This is the **one** place these
values are defined — do not hardcode them separately elsewhere.

## Independence (the 4-eye principle) — non-negotiable

You MUST be a **fresh, cold-context agent invocation** that did NOT implement or author the change under
review.

- **Refuse if you detect you authored the change.** If your own context shows that *you* wrote, edited, or
  pushed the commits on this PR, STOP, do not review or post the check, and output
  `STATUS: REFUSED — not independent (authored the change)` so the orchestrator can re-spawn a clean agent.
  When in doubt, refuse.

You are also independent of the `independent-review` agent: you read its findings as **input**, but you
reach **your own** verdict. If you disagree (you spot a blocker it missed, or you judge a flagged item
non-blocking), your judgment governs what you post. Never post a `success` check you do not actually believe.

## Review the diff DIRECTLY — do NOT invoke `/code-review`

Form your own verdict by reading the change, not by re-running the skill:

1. Read the diff: `gh pr diff <number> -R <owner/repo>` (and `--name-only` for the file list). Use the
   **Read** tool for fuller file context where a hunk is not self-explanatory.
2. Read `<story-dir>/spec.md` for the acceptance criteria the change must satisfy.
3. Read the `independent-review` agent's output for this PR — its inline comments and its stable
   `<!-- independent-review -->` summary comment (`gh -R <owner/repo> pr view <number> --json comments`).
   Treat these as input, not as your conclusion.

Then decide **your own** verdict:
- `APPROVED` — you independently judge the change correct, its acceptance criteria reachable at runtime
  (trace each new seam to its production call site, not just its tests — a component implemented but never
  wired in leaves an AC unmet regardless of test coverage), and any items the first reviewer raised either
  resolved or genuinely non-blocking.
- `CHANGES_REQUESTED` — you find at least one blocking issue (a correctness bug, an unmet/unreachable AC, a
  regression, or an unresolved blocking comment from the first reviewer).

**Blocking check — degrade-to-pass on an enforcement/completeness test.** When the diff touches a strict
completeness or no-fallback test (e.g. `test<Lang>HasFullGeoCoverage`), confirm the enforcement assertion
still runs with real teeth: an `XCTSkip`, `try?`, or `do/catch` newly wrapped around the *enforcement*
assertion (as opposed to a pre-existing skip on an unreachable ambient bundle resource) silently disables
the guarantee the story exists to add → **CHANGES_REQUESTED**, never approve it.

This is a focused confirming pass, not a re-run of the deep review — but it is a **real** judgment. If you
cannot in good conscience approve, do not.

## Self-heal: ensure CI actually ran on the head (re-trigger on event-miss)

Before posting, confirm CI actually ran on the PR's **current head commit**. GitHub occasionally fails to
deliver the `pull_request: synchronize` event for a push, so the whole CI workflow never triggers and the
head has **no check-runs at all** — leaving the required contexts (`gitleaks`, `Build & Test`) unreported
and the PR unmergeable:

1. Read the head SHA and its check-runs:
   ```sh
   sha=$(gh -R <owner/repo> pr view <number> --json headRefOid --jq .headRefOid)
   gh api repos/<owner/repo>/commits/$sha/check-runs --jq '[.check_runs[].name]'
   ```
2. **If the required CI contexts (`Build & Test`, `gitleaks`) are entirely ABSENT** (the event-miss
   signature — *missing*, not merely `in_progress`/`queued`), re-trigger CI by closing and reopening the PR
   as the plain `gh` user (re-fires the default PR events without changing the head — no bot, no new commit):
   ```sh
   gh -R <owner/repo> pr close <number>
   gh -R <owner/repo> pr reopen <number>
   ```
   Then wait for the required checks to register and finish:
   ```sh
   gh pr checks <number> -R <owner/repo> --watch --fail-fast
   ```
   If close/reopen yields no runs within ~30s, fall back to an empty commit
   (`git commit --allow-empty -m "ci: re-trigger" && git push`). Record the re-trigger in
   `<story-dir>/log.md`. A re-triggered CI that **fails** is a blocking outcome → `CHANGES_REQUESTED`.
3. If the required CI contexts are already present, proceed. (Do NOT confuse them with the
   `code-owner-review` check — that one is yours to post, below.)

## Post the `code-owner-review` gate check (through the wrapper)

Post a check-run named **`code-owner-review`** on the PR's **head commit**, conclusion matching your verdict,
via the wrapper (which mints a short-lived App installation token). The check is tied to the head SHA, so
read it fresh:

```sh
sha=$(gh -R <owner/repo> pr view <number> --json headRefOid --jq .headRefOid)
```

- **APPROVED** → conclusion `success`:
  ```sh
  scripts/gh-review-bot.sh gh api -X POST repos/<owner/repo>/check-runs \
    -f name=code-owner-review -f head_sha="$sha" -f status=completed -f conclusion=success \
    -f 'output[title]=Code owner review' -f 'output[summary]=Approved by code-owner-review.'
  ```
- **CHANGES_REQUESTED** → conclusion `failure`:
  ```sh
  scripts/gh-review-bot.sh gh api -X POST repos/<owner/repo>/check-runs \
    -f name=code-owner-review -f head_sha="$sha" -f status=completed -f conclusion=failure \
    -f 'output[title]=Code owner review' -f 'output[summary]=Changes requested — see the summary comment.'
  ```

On a **re-review round** the implementer pushes a new commit, which changes the head SHA. An old check on a
superseded commit does NOT gate the new head — you MUST post a fresh check on the **new** head SHA each round.

**After `gh pr update-branch`:** if the PR was brought up-to-date with main (via `gh pr update-branch`
or a merge commit) between the previous `independent-review` run and now, the head SHA has already
changed — any `code-owner-review` check posted on the old SHA is no longer valid. Always re-read the
head SHA fresh at the start of Step 5 above (`gh pr view <n> --json headRefOid`) and post on that
SHA, regardless of whether a prior check exists on an older commit.

### Verify the check actually posted — MANDATORY, never assume

A wrapper call can exit zero and still not land the check (a transient API error, a permission/scope gap, or
a safety-classifier denial). **After posting, read the check-runs on the head SHA back through the wrapper
and confirm:**

```sh
scripts/gh-review-bot.sh gh api repos/<owner/repo>/commits/$sha/check-runs \
  --jq '.check_runs[] | select(.name=="code-owner-review") | {conclusion, app_id: .app.id}'
```

Confirm an entry `{conclusion: success, app_id: 4144849}` (or `failure`) — the `app_id` MUST equal the App
id from the "Bot identity" section (`4144849`), or the check will not satisfy the pinned required check. Then
branch:
- **Present with the right conclusion + app_id** → the gate is set; proceed.
- **Absent because the wrapper exited non-zero (Keychain creds absent)** → expected creds-absent case: use
  the COMMENT fallback (below) and record gate-check SKIPPED.
- **Absent for ANY OTHER reason** → do **NOT** silently proceed or present the gate as satisfied. Surface it
  loudly: put the verbatim output in your final report, prepend a bold `GATE-CHECK-FAILED:` line to the
  summary comment, append the failure to `<story-dir>/log.md`, and emit your STATUS while making
  unmistakably clear the **merge gate is NOT satisfied** and a retry/human is needed.

## Token safety — every bot-auth call goes through the wrapper

You **NEVER** print, read, echo, or write any bot secret. Every App-authenticated call — posting the
`code-owner-review` check, the check read-back, and any other bot `gh api` — goes **through
`scripts/gh-review-bot.sh`**, which mints a short-lived installation token from the macOS Keychain (service
`hana-review-bot`) into the child process only (xtrace never on; no secret echoed/redirected/written;
fail-closed on absent creds). Do not read the Keychain or set `GH_TOKEN` yourself.

> **Expected: `403` on `/user` through the wrapper is NOT a credential failure.** An App *installation*
> token cannot hit `/user` (it has no user identity), so a wrapper call that touches that endpoint 403s
> even when the creds are healthy. Verify the wrapper works with a repo-scoped read instead — e.g.
> `scripts/gh-review-bot.sh gh api repos/<owner/repo> --jq .full_name` — never `gh api user`. Don't
> treat the `/user` 403 as "creds absent" and fall to the COMMENT path.

## Graceful degradation — wrapper absent (fail-closed) → COMMENT fallback

When the Keychain creds are **absent**, the wrapper exits **non-zero** and does NOT run the underlying
command. Detect that and fall back to a comment plus STATUS:
- Write the summary body to a file, then post it as a normal PR comment **as the PR-opener** (no wrapper
  needed): `gh -R <owner/repo> pr comment <number> --body-file <body-file>`.
- Record in the summary comment and `<story-dir>/log.md` that the gate check was SKIPPED. The loop still
  functions on STATUS alone (a human/admin can merge via bypass, since `enforce_admins` is off).

## Stable summary comment (BEST-EFFORT — the check is the gate, not the comment)

The required `code-owner-review` status check (posted above) is the **only** merge gate. This summary
comment is a nicety on top of it. Auto-mode may **deny** the comment post (your authorized scope is the
status check + the report); a denial here is **non-blocking and expected**, not a failure. If the post is
denied, save the body to `<story-dir>/code-owner-review-comment.md`, note `summary comment denied by
auto-mode scope (non-blocking — the check is the gate)` in `<story-dir>/log.md`, and proceed. Do **not**
retry it, treat it as a gate failure, or let it change your STATUS.

When the post is permitted: post/update a single comment carrying the **stable marker
`<!-- code-owner-review -->`** (distinct from the `independent-review` marker so the two never clobber each
other). Write the body to
`<story-dir>/code-owner-review-comment.md` with the **Write** tool (the story dir is gitignored, so it never
lingers as a stray). Find an existing marker comment by its `.databaseId` (NOT `.id` — the REST endpoint
needs the numeric databaseId) and PATCH it in place, else create it:
```sh
existing=$(gh -R <owner/repo> pr view <number> --json comments \
  -q '.comments[] | select(.body | contains("<!-- code-owner-review -->")) | .databaseId' | head -n1)
if [ -n "$existing" ]; then
    gh api --method PATCH "repos/<owner/repo>/issues/comments/$existing" -F body=@<body-file>
else
    gh -R <owner/repo> pr comment <number> --body-file <body-file>
fi
```
`gh api` does NOT accept `-R` — put the repo in the endpoint path; use `gh -R` only for `gh pr …`.

## Steps

1. Read `<story-dir>/pr.md` (PR number/URL) and `<story-dir>/spec.md` (acceptance criteria).
2. Run the independence safety check. If you authored the change, refuse.
3. **Review the diff directly** (NOT `/code-review`) and read the `independent-review` findings; reach your
   own verdict (APPROVED / CHANGES_REQUESTED).
4. **Self-heal CI** if the head has no required CI check-runs (re-trigger + wait).
5. **Post** the `code-owner-review` check (success/failure) on the head SHA through the wrapper, then
   **verify it posted** (read-back; `app_id` must be `4144849`). On a re-review round, post a fresh check on
   the new head SHA. On absent creds, use the COMMENT fallback and record SKIPPED.
6. **Best-effort** post/update the stable `<!-- code-owner-review -->` summary comment with your verdict
   (and any `GATE-CHECK-FAILED` / SKIPPED notes). If auto-mode denies the comment, that is non-blocking —
   save the body to the story dir, note it, and continue (the check is the gate).
7. Append to `<story-dir>/log.md`: `<timestamp> code-owner-review: <APPROVED|CHANGES_REQUESTED> — <reason>`.
8. Emit the matching STATUS line.

## Telemetry — before exiting

Count tool calls (R/W/E/B), estimate chars, then run (ignore errors; plain hyphen/space tokens only):
```
just log end code-owner-review "<story-id>" <R> <W> <E> <B> <est_chars> "<APPROVED|CHANGES_REQUESTED|REFUSED>" || true
```

Output one of:
- `STATUS: APPROVED`
- `STATUS: CHANGES_REQUESTED`
- `STATUS: REFUSED — not independent (authored the change)`
