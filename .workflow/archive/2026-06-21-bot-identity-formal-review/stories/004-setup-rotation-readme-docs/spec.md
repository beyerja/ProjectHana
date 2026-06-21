# 004 — Docs: setup + token rotation + workflow README updates

## Title
Document the 3 human prerequisites, token rotation, and update `.workflow/README.md` for
bot-auth review, formal states, thread resolution, and the obligatory gate

## Goal
Let a fresh machine be provisioned for bot-identity reviews without an agent ever seeing the
token, and explain the new review behavior in the workflow docs. Covers the human-only
prerequisites, token rotation, and the workflow-level description of the new mechanics.

## Scope
- A `docs/` section (e.g. `docs/bot-review-setup.md`) covering the 3 human prerequisites and
  token rotation.
- Updates to `.workflow/README.md` describing bot-auth review, formal review states, thread
  resolution, and the obligatory gate.

## Acceptance Criteria
- [ ] A committed `docs/` page documents the 3 human prerequisites verbatim and step-by-step:
      (1) minting the fine-grained PAT as `Hanahuac-Bot` scoped to ONLY this repo with
      permissions Pull requests R/W, Contents read, Metadata read; (2) adding `Hanahuac-Bot` as
      a repo collaborator with Write access and accepting the invite; (3) storing the token in
      the Keychain via `security add-generic-password -a "$USER" -s hana-review-bot -U -w`.
- [ ] The docs explain that agents NEVER see the token — it is read only by
      `scripts/gh-review-bot.sh` (story 001) — and that all three prerequisites are
      human-performed out-of-band.
- [ ] A token ROTATION procedure is documented: mint a new PAT, update the Keychain item (the
      `-U` upsert form), revoke the old PAT — no repo/working-tree change required.
- [ ] `.workflow/README.md` is updated to describe: bot-authenticated formal review submission,
      the formal states (`APPROVE` / `REQUEST_CHANGES` / `COMMENT` fallback) alongside `STATUS`,
      thread resolution via `resolveReviewThread`, and the obligatory CODEOWNERS +
      branch-protection gate with its bootstrapping guard.
- [ ] The README cross-references the setup docs and the story-003 branch-protection activation
      command (when to flip the gate on).
- [ ] No token value or secret appears anywhere in the committed docs; only the commands a human
      runs and the service name `hana-review-bot`.

## Notes
- This story is documentation-only and can be authored in parallel with 001–003, but should
  reference their concrete artifacts (wrapper path, CODEOWNERS, activation command).
