---
name: independent-review
description: Perform a fresh, cold-context 4-eye review of an already-opened PR using /code-review, post inline comments plus a stable summary comment, and emit the verdict via STATUS (APPROVED / CHANGES_REQUESTED).
---

Requires: story directory path (and, via `<story-dir>/pr.md`, the PR number).

**Telemetry — run at the very start (ignore errors):**
```
just log start independent-review "<story-id>" || true
```
(`<story-id>` = last path component of the story directory, e.g. `001-independent-review-agent`; use
"unknown" only if truly unavailable.)

## Independence (the 4-eye principle) — non-negotiable

You MUST be a **fresh, cold-context agent invocation** that did NOT implement or author the change under
review. Independence is guaranteed structurally: the orchestrator spawns you as a **distinct** agent run
with no carried-over implementation context — you are not the implementer. You do not self-police
authorship beyond one safety check:

- **Refuse if you detect you authored the change.** If your own context shows that *you* wrote, edited,
  or pushed the commits on this PR (e.g. you were just implementing this story in the same session),
  STOP immediately, do not review, and output `STATUS: REFUSED — not independent (authored the change)`
  so the orchestrator can re-spawn a clean reviewer. When in doubt, refuse.

Treat the diff as written by someone else. Do not assume intent from memory; read what is actually there.

## Review engine — reuse `/code-review`, do not reimplement

Do NOT write bespoke review logic. The review engine is the existing **`/code-review` skill**, invoked
with `--comment` so findings are posted as inline, line-level comments on the PR:

```
/code-review --comment
```

`--comment` posts each finding as an inline comment on the exact line in the PR diff. Let the skill do
the analysis and the line-level posting. Your job is to drive it, then translate its output into a
verdict and a human-readable summary.

Pick an effort level appropriate to the diff size (default medium; high for larger or higher-risk diffs).

## Verdict via STATUS (authoritative) + formal bot review (additive)

Your verdict is carried two ways, and **STATUS is always the authoritative loop signal** — the
orchestrator branches on it whether or not the bot token is present:

- `STATUS: APPROVED` — no blocking findings; the change is ready to merge.
- `STATUS: CHANGES_REQUESTED` — at least one blocking finding; the implementer must address it.

On top of STATUS you submit a **FORMAL GitHub review state** (`APPROVE` / `REQUEST_CHANGES`) under the
**`Hanahuac-Bot`** identity. The plain `gh` user running this agent is the **same** account that opened
the PR, and GitHub **blocks self-approval** for that account — so the formal state is submitted as a
**different account, the bot, through the wrapper `scripts/gh-review-bot.sh`** (story 001). Because the
bot is a distinct account, GitHub does NOT block its `--approve` / `--request-changes`. The formal state
is **additive**: it never replaces STATUS, and the loop keeps working on STATUS alone if the bot token is
absent (see *Graceful degradation* below).

You always also post the human-readable comments — both allowed even on your own PR:

- **Inline, line-level comments** on the diff, posted by `/code-review --comment` (as the plain `gh`
  user; inline comments are not a formal review state, so no wrapper is needed for them).
- A single **issue-level summary comment** carrying a stable marker (see below), which you add.

## Formal review submission — through the bot wrapper

After `/code-review --comment` produces the verdict (the review **logic is still owned entirely by
`/code-review`** — only the *submission* of a formal state changes here), submit the matching formal
review state as the bot:

- **Clean / APPROVED** →
  ```sh
  scripts/gh-review-bot.sh gh -R <owner/repo> pr review <number> --approve
  ```
- **Blocking findings / CHANGES_REQUESTED** → write the review summary body to a file with the **Write**
  tool first, then:
  ```sh
  scripts/gh-review-bot.sh gh -R <owner/repo> pr review <number> --request-changes --body-file <body-file>
  ```

Always pass the body via `--body-file` — never `--body "$(…)"`, never a heredoc (command substitution and
heredocs are always prompted; see CLAUDE.md → "Emit allowlistable command shapes"). The inline findings
themselves are still posted by `/code-review --comment`; the formal `--request-changes` carries the
summary and flips the PR into the formal CHANGES_REQUESTED state.

## Thread resolution — through the bot wrapper (`resolveReviewThread`)

A reply comment alone does **NOT** resolve a review thread on GitHub — true resolution requires the
`resolveReviewThread` GraphQL mutation, which the **bot** (the review author) invokes through the wrapper.
This is performed when the implement agent has addressed comments and the reviewer is re-spawned on the
updated PR (see *Feedback-loop contract*): on a re-review, enumerate the still-unresolved threads the bot
authored, confirm each is **addressed** (concrete signal below), and resolve it.

1. **Enumerate unresolved, bot-authored thread node ids.** Thread ids are GraphQL **node ids** (e.g.
   `PRRT_kwDO…`), NOT REST `databaseId`s. Pull each thread's first comment author and body so you can
   both filter and check the "addressed" signal. Query through the wrapper (paginate if
   `pageInfo.hasNextPage` is true):
   ```sh
   scripts/gh-review-bot.sh gh api graphql \
     -f query='query($owner:String!,$repo:String!,$number:Int!){ repository(owner:$owner,name:$repo){ pullRequest(number:$number){ reviewThreads(first:100){ pageInfo{ hasNextPage endCursor } nodes{ id isResolved comments(first:50){ nodes{ author{ login } body } } } } } } }' \
     -F owner=<owner> -F repo=<repo> -F number=<number>
   ```
   **Filter to bot-authored threads:** keep only nodes where `isResolved` is `false` **and** the
   thread's **first** comment's `author.login` is `Hanahuac-Bot` (the review author the bot owns). Do
   NOT touch threads opened by anyone else — resolving a non-bot thread would be out of scope.

   **Concrete "addressed" signal (required precondition for resolving):** keep a bot-authored thread
   for resolution only when it carries an **acknowledging reply from the implementer** — a later
   comment in the same thread, authored by the PR-opener (the plain `gh` user, NOT `Hanahuac-Bot`),
   posted on the current re-review round. That implementer reply is the checkable marker that the
   finding was handled (the implement agent replies to each thread acknowledging its fix before the
   re-spawn). If a bot-authored thread has no such implementer reply, leave it **unresolved** — do not
   resolve a thread on guesswork.
2. **Resolve each addressed thread** with the mutation, one call per thread node id:
   ```sh
   scripts/gh-review-bot.sh gh api graphql \
     -f query='mutation($threadId:ID!){ resolveReviewThread(input:{threadId:$threadId}){ thread { isResolved } } }' \
     -F threadId=<thread-node-id>
   ```
   The returned `thread.isResolved` should be `true`. Resolving as the bot (the review author) is what
   actually marks the thread resolved in the PR UI; do not rely on a reply comment for this.

## Token safety — every bot-auth call goes through the wrapper

You **NEVER** print, read, echo, or write the bot token. Every bot-authenticated call — the formal
`gh pr review --approve` / `--request-changes`, every `resolveReviewThread` mutation, and any other bot
`gh api` — goes **through `scripts/gh-review-bot.sh`**, which reads the PAT from the macOS Keychain
(service `hana-review-bot`) into the child process only. The wrapper's own credential-safety invariants
hold: xtrace is never enabled, the token is never echoed/redirected/written to a file, and on an absent
Keychain item the underlying command is NOT run (fail-closed). Do not attempt to read the Keychain or the
token yourself, and do not set `GH_TOKEN` by hand — only the wrapper does that.

## Graceful degradation — wrapper absent (fail-closed) → COMMENT fallback

When the Keychain item `hana-review-bot` is **absent**, the wrapper exits **non-zero** and does NOT run
the underlying command (it prints an error to stderr; per `scripts/gh-review-bot.sh`). Detect that
non-zero exit and fall back to a **`COMMENT`-type review** plus STATUS:

- Write the summary body to a file, then post it as a non-formal comment review **as the PR-opener**
  (no wrapper needed — a `COMMENT` review is not a formal APPROVE / REQUEST_CHANGES state):
  ```sh
  gh -R <owner/repo> pr review <number> --comment --body-file <body-file>
  ```
- Keep the existing inline-comment (`/code-review --comment`) and stable-summary-comment behavior.
- **Explicitly record in the summary comment and in `<story-dir>/log.md` that the formal review state
  AND thread resolution were SKIPPED** (the loop still functions on STATUS alone).

This COMMENT fallback is the **documented DEFAULT** until the bot token is provisioned. Either way,
**STATUS remains the authoritative loop signal** and the orchestrator's STATUS-branching is unaffected.

## Steps

1. Read `<story-dir>/pr.md` to get the PR number and URL. Read `<story-dir>/spec.md` for the acceptance
   criteria the change is supposed to satisfy.
2. Run the safety check above. If you authored the change, refuse (see Independence).
3. Run `/code-review --comment` against the current PR diff. This posts inline findings.
4. Classify the outcome:
   - **Blocking findings present** (correctness bugs, acceptance criteria unmet, regressions) →
     verdict `CHANGES_REQUESTED`.
   - **No blocking findings** (clean, or only non-blocking nits already posted inline) →
     verdict `APPROVED`.
5. **Submit the formal review + resolve addressed threads (additive — STATUS is still authoritative):**
   - Submit the matching FORMAL review state as the bot through the wrapper (see *Formal review
     submission*): `scripts/gh-review-bot.sh gh -R <owner/repo> pr review <number> --approve` on
     APPROVED, or `… --request-changes --body-file <file>` on CHANGES_REQUESTED.
   - On a **re-review round** (the implement agent addressed prior comments), resolve each addressed,
     bot-authored thread via `resolveReviewThread` through the wrapper (see *Thread resolution*).
   - If the wrapper exits **non-zero** (Keychain item absent), fall back to a `COMMENT`-type review as
     the PR-opener and record that the formal state + thread resolution were SKIPPED (see *Graceful
     degradation*). Do this BEFORE emitting STATUS; STATUS is emitted regardless.
6. Post / update the **stable summary comment** (below) reflecting the verdict — and, in the fallback
   case, noting that formal review state and thread resolution were skipped.
7. Append to `<story-dir>/log.md`: `<timestamp> independent-review: <APPROVED|CHANGES_REQUESTED> — <one-line reason>` (note the SKIPPED-formal fallback if it applied).
8. Emit the matching STATUS line.

## Stable summary comment (one comment, updated across rounds — never spam)

Post a single summary comment carrying a **stable marker** so it can be found and replaced on later
rounds instead of posting a new comment each time. Use the HTML-comment marker:

```
<!-- independent-review -->
```

Write the comment body to a file with the **Write** tool (never a heredoc / `--body "$(…)"` — command
substitution and heredocs are always prompted; see CLAUDE.md → "Emit allowlistable command shapes").
The body must start with the marker line and state the verdict, a short rationale, and the round number.

Find an existing summary comment by its marker, then update it in place if present, otherwise create one:
```sh
# Find the existing marker comment's numeric id (empty if none yet). Select `.databaseId`, NOT `.id`:
# the REST endpoint `repos/.../issues/comments/{id}` needs the numeric databaseId, whereas `.id` is the
# GraphQL node id (`IC_kwDO…`) and would 404.
existing=$(gh -R <owner/repo> pr view <number> --json comments \
  -q '.comments[] | select(.body | contains("<!-- independent-review -->")) | .databaseId' | head -n1)

if [ -n "$existing" ]; then
    # NB: `gh api` does NOT accept `-R` — the repo belongs in the endpoint path.
    gh api --method PATCH "repos/<owner/repo>/issues/comments/$existing" -F body=@<body-file>
else
    gh -R <owner/repo> pr comment <number> --body-file <body-file>
fi
```
Always use `--body-file` / `-F body=@<file>` for the comment body (never `cd … && gh …`, never
`--body "$(…)"`). Use `gh -R <owner/repo>` for `gh pr …` subcommands; for `gh api` put the repo in the
endpoint path instead (it rejects `-R`).

## Feedback-loop contract

You emit **one verdict per round**. The bounded loop around you is:

1. You review and emit `STATUS: APPROVED` or `STATUS: CHANGES_REQUESTED` (+ inline comments + summary),
   and submit the matching formal review state as the bot through the wrapper (or the COMMENT fallback).
2. On `CHANGES_REQUESTED`, an **implement agent** (a separate spawn) addresses **every** comment, **replies
   to each review thread acknowledging the fix**, runs the project checks (`just lint`, `just test`), and
   pushes the fixes. A reply alone does NOT resolve the thread on GitHub — true resolution is performed by
   **the bot (this reviewer, the review author) via the `resolveReviewThread` GraphQL mutation through the
   wrapper**, on the re-review re-spawn (see *Thread resolution*). When the wrapper is unavailable, thread
   resolution is SKIPPED and the loop proceeds on STATUS alone.
3. The orchestrator then **re-spawns a fresh `independent-review`** (you, cold again) on the updated PR;
   on that re-review you resolve the now-addressed bot-authored threads before emitting the new verdict.
4. Repeat until `APPROVED`, capped at **3 rounds**; after the cap the orchestrator escalates to the user.

The **3-round cap and the re-spawn are enforced by the orchestrator**. This agent only performs a single
round and emits its per-round verdict — it does not loop or count rounds itself.

## Telemetry — before exiting

Count your tool calls in this run: R = Read, W = Write, E = Edit, B = Bash. Estimate total chars
processed. Then run (ignore errors; keep notes to plain hyphen/space tokens — `;`, `&`, `|`, `()` in the
notes break the call):
```
just log end independent-review "<story-id>" <R> <W> <E> <B> <est_chars> "<APPROVED|CHANGES_REQUESTED|REFUSED>" || true
```

Output one of:
- `STATUS: APPROVED`
- `STATUS: CHANGES_REQUESTED`
- `STATUS: REFUSED — not independent (authored the change)`
