# Obligatory review gate — how `main` is protected

This repository makes independent review **obligatory**: an approving review from the code owner
(`@Hanahuac-Bot`, see [`CODEOWNERS`](./CODEOWNERS)) is required before any change merges to `main`.

## The gate is a repository RULESET, not classic branch protection

The *review* requirement comes from a pre-existing **repository ruleset** (`main`, id `17373423`,
`enforcement: active`) whose `pull_request` rule sets `require_code_owner_review: true`. This is
**separate** from classic branch protection, which sets **no** required reviews
(`required_pull_request_reviews: null`) but does still require CI checks — see "Two complementary
gates" below. The review gate is two pieces working together:

1. **The ruleset** (already active; managed in the GitHub UI under Settings → Rules → Rulesets) —
   the part that actually *enforces* a code-owner approval.
2. **[`CODEOWNERS`](./CODEOWNERS)** (committed) — designates `@Hanahuac-Bot` as the code owner for
   the whole repo (`* @Hanahuac-Bot`).

## Committing CODEOWNERS activates the gate — provision the bot FIRST

There is **no separate activation command**. The ruleset's `require_code_owner_review` does nothing
while no CODEOWNERS file exists, but the instant CODEOWNERS lands on `main`, every PR to `main`
requires an approving review from `@Hanahuac-Bot`.

> **Bootstrapping order (learned the hard way).** Provision the bot — add `Hanahuac-Bot` as a Write
> collaborator and store its **classic** PAT in the Keychain (see
> [`docs/bot-credentials.md`](../docs/bot-credentials.md)) — **before** CODEOWNERS reaches `main`.
> Otherwise the first PR after CODEOWNERS lands deadlocks: it needs a bot approval the bot cannot yet
> give. (This is exactly what happened to the closing PR of the feature that introduced this gate.)

## How the bot approves

The `independent-review` agent submits the code owner's approval as `@Hanahuac-Bot` through the
wrapper, which never exposes the token:

```sh
scripts/gh-review-bot.sh gh -R beyerja/ProjectHana pr review <number> --approve
```

A bot `APPROVE` flips a code-owner-gated PR from `mergeStateStatus: BLOCKED` to `CLEAN`. (`gh`'s
`reviewDecision` field can read empty when the required approver is mapped via a ruleset rather than
the classic reviewers list — `mergeStateStatus: CLEAN` is the authoritative signal that the gate is
satisfied.)

## Two complementary gates: review (ruleset) + CI (classic protection)

Two separate, already-active mechanisms gate `main`, each owning a different requirement:

- **Code-owner review** → the **ruleset** `17373423` (this doc's subject).
- **CI status checks** → **classic branch protection** on `main` (separate from the ruleset)
  requires `gitleaks` and `Build & Test`, with `strict: true` (branch must be up to date). It sets
  **no** required reviews (`required_pull_request_reviews: null`) — the review requirement comes
  entirely from the ruleset. See [`SECURITY.md`](../SECURITY.md) for how that CI protection is set up.

So a merge to `main` needs **both** a `@Hanahuac-Bot` approval (ruleset) **and** green required checks
(classic protection). The removed `branch-protection-main.json` was redundant: it duplicated the
code-owner-review requirement the ruleset already enforces (while merely re-stating the CI checks
classic protection already requires), so dropping it changes nothing that is actually enforced.

Inspect the CI side with:

```sh
gh api repos/beyerja/ProjectHana/branches/main/protection
```

## Inspect or manage the gate

```sh
gh api repos/beyerja/ProjectHana/rulesets             # list rulesets
gh api repos/beyerja/ProjectHana/rulesets/17373423    # this gate's rules
```

To temporarily lift the gate (e.g. to recover from a deadlock), edit or disable the ruleset in the
GitHub UI (Settings → Rules → Rulesets → `main`), or add yourself as a bypass actor.
