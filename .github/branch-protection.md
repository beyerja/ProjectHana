# Obligatory review gate — how `main` is protected

This repository makes independent review **obligatory**: an approving review from the code owner
(`@Hanahuac-Bot`, see [`CODEOWNERS`](./CODEOWNERS)) is required before any change merges to `main`.

## The gate is a repository RULESET, not classic branch protection

Enforcement comes from a pre-existing **repository ruleset** (`main`, id `17373423`,
`enforcement: active`) whose `pull_request` rule sets `require_code_owner_review: true`. This is
**separate** from classic branch protection — `gh api repos/beyerja/ProjectHana/branches/main/protection`
shows no required reviews. The gate is two pieces working together:

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

## CI checks are NOT part of this gate

The ruleset enforces code-owner review only; it does **not** make CI status checks a required merge
gate. The feature workflow's own `wait-for-ci` step already blocks merges on red CI, so the
autonomous path stays safe. If you also want CI to be a hard gate for **manual / UI** merges, add a
`required_status_checks` rule (contexts `gitleaks`, `Build & Test`) to ruleset `17373423` in the
GitHub UI.

## Inspect or manage the gate

```sh
gh api repos/beyerja/ProjectHana/rulesets             # list rulesets
gh api repos/beyerja/ProjectHana/rulesets/17373423    # this gate's rules
```

To temporarily lift the gate (e.g. to recover from a deadlock), edit or disable the ruleset in the
GitHub UI (Settings → Rules → Rulesets → `main`), or add yourself as a bypass actor.
