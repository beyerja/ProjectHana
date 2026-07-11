<!-- code-owner-review -->
## Code-owner review — merge gate

**Verdict: APPROVED** — `code-owner-review` check posted with conclusion `success` on head `7fd95f4663a0fc90db643a98f0ef778a33b0f121` (check-run id `86581392852`, App id `4144849`; read-back verified).

### Independent re-verification (direct diff read, no /code-review)

- **triage-dep-prs jq fix** — traced the query semantics myself: the old `.labels[].name == "dependencies"` emits nothing on an empty labels array (poisoning the whole `select`); the new `(.labels | map(.name) | index("dependencies")) != null` yields a proper boolean, and `(.author.is_bot == true or (.author.login | test("\\[bot\\]|^app/")))` correctly catches the `app/dependabot` login form. Shell/jq escaping is correct.
- **`.gitignore`** — `.workflow/archive/*/telemetry/` is valid glob syntax and matches the untracked local telemetry dirs the rule exists to fence off; rationale (secret-shaped logged text vs. gitleaks) is sound.
- **`gh` argument reordering** (code-owner-review.md, independent-review.md) — both orderings are valid gh CLI; pure allowlist prefix-match improvement, no behavior change.
- **verify-feature.md** — fetch-in-worktree + plain `git show origin/main:<path>` is correct: a worktree shares the primary's object store and remote-tracking refs.
- **implement-story.md / story-workflow.md** — prose-only process rules; nothing removed, consistent with CLAUDE.md command shapes.
- **Archive move** — 49 tracked `.md` files, no code surface; gitleaks green on head.
- **CI** — all 4 checks completed/success on `7fd95f4` (no event-miss; no re-trigger needed).
- The first reviewer's one inline note (remaining `-R`-first shapes in triage-dep-prs.md) is a prompt-cost nit — genuinely non-blocking, follow-up-sized. The earlier empty COMMENTED review was an interrupted attempt and is disregarded.

Note: `mergeStateStatus` is `BEHIND` (main advanced); the gate check is SHA-bound, so after any `gh pr update-branch` a fresh check must be posted on the new head.
