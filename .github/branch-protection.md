# Obligatory review gate — branch protection for `main`

This repository makes independent review **obligatory**: a code-owner approval from the bot
(`@Hanahuac-Bot`, see [`CODEOWNERS`](./CODEOWNERS)) is required before any change merges to `main`.

The gate is made of two pieces:

1. **[`CODEOWNERS`](./CODEOWNERS)** (committed) — designates `@Hanahuac-Bot` as the required code
   owner for the whole repo (`* @Hanahuac-Bot`).
2. **Branch protection on `main`** (activated by the command below) — the part that actually
   *enforces* the gate by requiring a code-owner approval before merge.

## Why committing CODEOWNERS is safe mid-run

Committing `CODEOWNERS` **does not block any merge on its own**. CODEOWNERS only declares *who*
owns which paths; it has no enforcement effect until branch protection references it via
`required_pull_request_reviews.require_code_owner_reviews`. So this file is safe to commit while
this run's own PRs are still in flight — nothing is gated yet.

## FINAL ACTIVATION STEP — run ONLY AFTER this run's own PRs are merged

> **Bootstrapping guard.** Do **NOT** run the activation command mid-run. Enabling branch
> protection while this run's own PRs are still open would deadlock the workflow: every open PR
> would suddenly require a code-owner approval that the autonomous workflow cannot grant for its
> own in-flight changes. Activate the gate **only after** all of this run's PRs have merged to
> `main`, as the very last step.

The JSON request body lives in a committed file so the command stays a clean, copy-pasteable,
allowlistable shape (no heredoc, no inline JSON, no `cd &&`). Run from the repo root:

```sh
gh api -X PUT repos/beyerja/ProjectHana/branches/main/protection --input .github/branch-protection-main.json
```

This enables branch protection on `main` requiring **one approving review from the code owner**
(`require_code_owner_reviews: true`, `required_approving_review_count: 1`). The body
([`.github/branch-protection-main.json`](./branch-protection-main.json)) also sets
`enforce_admins: true`, `dismiss_stale_reviews: true`, and disables force-pushes/deletions; status
checks and push restrictions are left explicitly unset (`null`).

## Verify the gate is active

```sh
gh api repos/beyerja/ProjectHana/branches/main/protection
```

## Deactivation / rollback

To remove branch protection from `main` (e.g. to recover from a deadlock or reconfigure):

```sh
gh api -X DELETE repos/beyerja/ProjectHana/branches/main/protection
```
