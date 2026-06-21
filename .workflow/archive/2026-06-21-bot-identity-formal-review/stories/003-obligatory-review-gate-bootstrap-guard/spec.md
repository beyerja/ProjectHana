# 003 — Obligatory review gate (CODEOWNERS + branch protection) with bootstrapping guard

## Title
Commit `.github/CODEOWNERS` assigning the repo to `@Hanahuac-Bot` and a single ready-to-run
branch-protection activation command, without enabling the gate mid-run

## Goal
Make independent review OBLIGATORY: a code-owner approval from the bot is required before merge
to `main`. The gate is set up by committing CODEOWNERS plus a documented, ready-to-run
`gh api` branch-protection command — but it MUST NOT be enabled while this run's own PRs are
in flight, or the workflow would deadlock on its own un-reviewed PRs (bootstrapping guard).

## Scope
- `.github/CODEOWNERS` (committed).
- A documented, single, copy-pasteable `gh api` branch-protection activation command (in docs —
  e.g. the setup docs from story 004, or an adjacent `.github`/`docs` note). The command is
  committed but NOT executed mid-run.

## Acceptance Criteria
- [ ] `.github/CODEOWNERS` is committed and assigns the repository (e.g. `* @Hanahuac-Bot`) to
      `@Hanahuac-Bot` as the required code owner.
- [ ] A single ready-to-run `gh api` command that enables branch protection on `main` requiring
      an approving review from the code owner is committed in documentation. The command is
      self-contained and copy-pasteable (allowlistable shape; no `cd &&`, no heredoc payload —
      if a JSON body is needed it is written to a committed file passed via `--input <file>`).
- [ ] The branch-protection gate is NOT enabled during this run: the docs/commit state clearly
      mark it as the FINAL activation step to run only AFTER this run's own PRs are merged.
      Bootstrapping guard is explicit so the workflow does not deadlock on its own PRs.
- [ ] CODEOWNERS alone (committed) does not block merges until branch protection is activated —
      verified by reasoning/doc note that committing CODEOWNERS is safe mid-run.
- [ ] The activation command and the guard are cross-referenced from the workflow README
      (coordinate with story 004) so a human knows exactly when and how to flip the gate on.

## Notes
- Committing CODEOWNERS is safe mid-run; only branch protection enforces the gate, so only its
  activation is deferred.
- No real token required to satisfy this story (CODEOWNERS is a committed file; the activation
  command is documented, not run).
