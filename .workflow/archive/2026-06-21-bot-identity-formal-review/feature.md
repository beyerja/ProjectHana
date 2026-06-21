# Feature: Bot-identity formal PR reviews + obligatory review gate

## Goal
Give the `independent-review` agent a **separate GitHub identity** (the existing
`Hanahuac-Bot` account) so it can submit **real** GitHub `APPROVE` / `REQUEST_CHANGES`
review states (impossible today because the reviewer authenticates as the same user that
opened the PR). Make independent review **obligatory** via branch protection, and make
addressed comments **truly resolved** via the `resolveReviewThread` GraphQL mutation.

This builds on the shipped `independent-review` agent and is the deferred enhancement noted
in the prior feature's Out of Scope.

## Safety model for the bot token (hard requirement)
The token must be built so an agent **cannot accidentally read or commit it**:
- Stored in the **macOS Keychain** (service `hana-review-bot`), outside every working
  directory — so it is never in the repo working tree and physically cannot be `git add`ed,
  and never surfaces in a Read/Grep of the repo.
- Accessed **only** through a committed wrapper (e.g. `scripts/gh-review-bot.sh`) that reads
  the token from Keychain into a subprocess `GH_TOKEN` and `exec`s `gh`/`curl` **without ever
  printing it** (`set +x`, no echo). Agents auth as the bot ONLY via this wrapper and never
  call the raw `security find-generic-password -w` read or echo `$GH_TOKEN`.
- A **secret-scanning pre-commit hook** blocks any commit containing a `github_pat_…` /
  `ghp_…` token pattern (defense in depth against accidental commits).

## Human prerequisites (provisioned by the user; agents never see the token)
1. Fine-grained PAT minted as `Hanahuac-Bot`, scoped to ONLY this repo, permissions:
   Pull requests R/W, Contents read, Metadata read.
2. `Hanahuac-Bot` added as a repo collaborator with Write access (invite accepted).
3. Token stored in Keychain: `security add-generic-password -a "$USER" -s hana-review-bot -U -w`.

## Acceptance Criteria
- [ ] A committed wrapper `scripts/gh-review-bot.sh` fetches the token from the Keychain
      service `hana-review-bot` into a subprocess `GH_TOKEN` and execs the underlying command
      without ever printing the token; it fails with a clear message if the Keychain item is
      absent. Verified to never write the token to disk or stdout.
- [ ] The `independent-review` agent submits its verdict as a **formal** GitHub review through
      the wrapper: `APPROVE` on clean, `REQUEST_CHANGES` with inline comments otherwise. It
      still emits its `STATUS` (`APPROVED` / `CHANGES_REQUESTED`) as the workflow loop driver
      (formal state is additive, not a replacement for STATUS). It still refuses if it authored
      the change (4-eye principle preserved).
- [ ] When the implement agent addresses comments, the corresponding review threads are
      **truly resolved** via the `resolveReviewThread` GraphQL mutation (through the bot
      wrapper), not merely replied to.
- [ ] Independent review is **obligatory**: a `.github/CODEOWNERS` assigning the repo to
      `@Hanahuac-Bot` plus branch-protection on `main` requiring an approving review from the
      code owner. Merge is blocked until the bot formally approves. Documented `gh api` command
      to enable it is committed.
- [ ] **Bootstrapping guard:** the obligatory branch-protection gate is enabled only as the
      FINAL activation step (after this run's own PRs are merged), so the workflow does not
      deadlock on its own un-reviewed PRs. The run documents/leaves a single ready-to-run
      activation command if it cannot safely enable it mid-run.
- [ ] A secret-scanning pre-commit hook is installed and committed that rejects token-like
      strings.
- [ ] `independent-review.md`, `story-workflow.md`, and `.workflow/README.md` updated to
      describe bot-auth review, formal states, thread resolution, and the obligatory gate.
- [ ] Setup is documented (a `docs/` or README section) covering the 3 human prerequisites and
      token rotation, so a fresh machine can be provisioned without an agent seeing the token.

## Constraints
- **Meta-feature** — modifies workflow tooling (`.claude/agents/`, `scripts/`, `.github/`,
  `.workflow/README.md`). Per the orchestrator Step 0 guard, run **in the PRIMARY checkout on a
  feature branch — NO worktree**.
- The token is provisioned by the human out-of-band; agents must operate as if the token may
  not yet be present and degrade gracefully (build + reason about plumbing, guard live calls on
  the Keychain item existing). Do NOT block the whole build on the token.
- Reuse the existing `/code-review` skill for the diff review; the bot identity only changes the
  *submission* (formal review + comments + thread resolution), not the review logic.
- Follow CLAUDE.md "Emit allowlistable command shapes" rules throughout.
- Never print, log, commit, or read-for-display the bot token. The wrapper is the only
  sanctioned path to the credential.

## Out of Scope
- Migrating from a fine-grained PAT to a GitHub App installation token (possible future
  hardening; not built now).
- Changes to CI structure beyond the new pre-commit hook and branch-protection gate.
