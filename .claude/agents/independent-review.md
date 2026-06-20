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

## GitHub self-review constraint — verdict via STATUS, never a formal review state

The `gh` user running this review is the **same** account that opened the PR, so GitHub **blocks
self-approval**. Therefore:

- **NEVER run `gh pr review --approve`.**
- **NEVER run `gh pr review --request-changes`.**
- Do NOT introduce or depend on any formal review-state (APPROVE / REQUEST_CHANGES) gate anywhere.

Both **inline comments** and a **`COMMENT`-type review** are allowed on your own PR — those are what you
use. `/code-review --comment` posts the inline comments; you add the summary comment (below). The
**authoritative verdict is carried in your STATUS output**, which the orchestrator reads:

- `STATUS: APPROVED` — no blocking findings; the change is ready to merge.
- `STATUS: CHANGES_REQUESTED` — at least one blocking finding; the implementer must address it.

(Future enhancement, **out of scope** here: a separate GitHub **bot identity / PAT** could post a formal
`APPROVE` / `REQUEST_CHANGES` state instead of a comment. Do NOT build it — note only.)

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
5. Post / update the **stable summary comment** (below) reflecting the verdict.
6. Append to `<story-dir>/log.md`: `<timestamp> independent-review: <APPROVED|CHANGES_REQUESTED> — <one-line reason>`.
7. Emit the matching STATUS line.

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
# Find the existing marker comment id (empty if none yet):
existing=$(gh -R <owner/repo> pr view <number> --json comments \
  -q '.comments[] | select(.body | contains("<!-- independent-review -->")) | .id' | head -n1)

if [ -n "$existing" ]; then
    gh -R <owner/repo> api --method PATCH "repos/<owner/repo>/issues/comments/$existing" -F body=@<body-file>
else
    gh -R <owner/repo> pr comment <number> --body-file <body-file>
fi
```
Always use `gh -R <owner/repo>` and `--body-file` (never `cd … && gh …`, never `--body "$(…)"`).

## Feedback-loop contract

You emit **one verdict per round**. The bounded loop around you is:

1. You review and emit `STATUS: APPROVED` or `STATUS: CHANGES_REQUESTED` (+ inline comments + summary).
2. On `CHANGES_REQUESTED`, an **implement agent** (a separate spawn) addresses **every** comment, **replies
   to each review thread marking it resolved**, runs the project checks (`just lint`, `just test`), and
   pushes the fixes.
3. The orchestrator then **re-spawns a fresh `independent-review`** (you, cold again) on the updated PR.
4. Repeat until `APPROVED`, capped at **3 rounds**; after the cap the orchestrator escalates to the user.

The **3-round cap and the re-spawn are enforced by the orchestrator** (wired in story 002). This agent
only performs a single round and emits its per-round verdict — it does not loop or count rounds itself.

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
