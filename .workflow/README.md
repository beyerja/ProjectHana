# Workflow State

This directory is managed by the feature-orchestrator agent and its sub-agents.

## Structure

```
.workflow/
  feature.md              # Feature spec (written by clarify-feature)
  stories.md              # Story list with statuses
  log.md                  # Global phase transition log
  stories/
    <NNN>-<slug>/
      spec.md             # Story spec and acceptance criteria
      tasks.md            # Task checklist
      status.md           # Current status (pending | in-progress | merged | done)
      pr.md               # PR URL and number
      log.md              # Story-level event log
```

## Statuses

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in-progress` | Story workflow is running |
| `merged` | PR merged, awaiting verification |
| `done` | Verified and complete |

## Per-story lifecycle (`story-workflow`)

Each story runs through `story-workflow`, which spawns a dedicated sub-agent per step:

1. **Break tasks** — `break-tasks`.
2. **Implement** — `implement-story` (the implement agent).
3. **Create PR** — `create-pr`.
4. **Wait for CI** — `wait-for-ci`. Must be green before review; on failure, re-implement and re-push.
5. **Independent review** — runs **after CI passes** so the reviewer sees code that builds. A fresh,
   **cold-context** `independent-review` agent — a **separate spawn from the implement agent** (the
   4-eye principle: the change is reviewed by someone who did not write it) — reviews the PR diff and
   emits a verdict via STATUS:
   - `CHANGES_REQUESTED` → a separate implement agent addresses every inline comment, replies to each
     thread marking it resolved, runs `just lint`/`just test`, and pushes; then a **fresh**
     `independent-review` runs again. This feedback loop is **bounded to 3 rounds**; after 3 rounds
     without approval the workflow **escalates to the user** instead of looping further.
   - `APPROVED` → continue.
6. **Merge** — once the reviewer emits `APPROVED` **and** CI is green, the workflow merges
   **autonomously** by spawning `merge-pr`. There is **no human review/merge gate**: the workflow never
   pauses for the user to review or merge, and never assumes the user merged manually.
7. **Verify** — `verify-story` checks the acceptance criteria; on failure it re-implements.

## Obligatory review gate (CODEOWNERS + branch protection)

Independent review is **obligatory**: a code-owner approval from `@Hanahuac-Bot` is required before
merging to `main`. This is set up by [`.github/CODEOWNERS`](../.github/CODEOWNERS) (assigns the repo
to the bot) plus branch protection on `main`.

### Bot-authenticated formal review submission

The `independent-review` agent submits a **formal GitHub review state** under the **`Hanahuac-Bot`**
identity via `scripts/gh-review-bot.sh gh pr review`. A separate bot account is required because the
plain `gh` user running the workflow is the **same** account that opened the PR, and GitHub **blocks
self-approval** by the PR opener — the bot, as a distinct collaborator, is not blocked. The wrapper
reads the bot's token from the macOS Keychain and never exposes it; agents only ever invoke the
wrapper. See **[`docs/bot-credentials.md`](../docs/bot-credentials.md)** for the canonical setup +
rotation steps and the token-safety guarantees.

### Formal review states (additive) vs the authoritative `STATUS`

The formal state is **additive** — it never replaces the agent's `STATUS:` line, which remains the
**authoritative loop signal** the orchestrator branches on:

- `APPROVE` — paired with `STATUS: APPROVED`.
- `REQUEST_CHANGES` — paired with `STATUS: CHANGES_REQUESTED`.
- `COMMENT` **fallback** — when the bot token is absent (the wrapper fails closed), the reviewer posts
  a non-formal `COMMENT`-type review as the PR-opener and records that the formal state was SKIPPED.
  The loop still functions on `STATUS` alone.

### Thread resolution via `resolveReviewThread`

A reply comment alone does **not** resolve a review thread on GitHub. True resolution requires the
`resolveReviewThread` GraphQL mutation, performed by the **bot** (the review author) through the
wrapper on a re-review round, after the implementer has acknowledged the fix on each thread. When the
bot token is absent, thread resolution is likewise SKIPPED and the loop proceeds on `STATUS` alone.

### The obligatory CODEOWNERS + ruleset gate (with bootstrapping guard)

Independent review is enforced by a repository **ruleset** (`main`, id `17373423`) requiring a
code-owner approval, combined with **[`CODEOWNERS`](../.github/CODEOWNERS)** designating
`@Hanahuac-Bot`. See **[`.github/branch-protection.md`](../.github/branch-protection.md)** for the
full picture — how the bot approves, the CI-gate caveat, and how to inspect/manage the ruleset.

> **Bootstrapping guard.** There is **no activation command** — committing `CODEOWNERS` *is* what
> activates the gate, because the ruleset's `require_code_owner_review` rule has no effect until a
> CODEOWNERS file exists. So provision the bot (Write collaborator + classic PAT in the Keychain)
> **before** `CODEOWNERS` reaches `main`; otherwise the next PR to `main` deadlocks on a bot approval
> that cannot yet be given.

The fuller setup/rotation docs live in **[`docs/bot-credentials.md`](../docs/bot-credentials.md)**.

## Starting the workflow

Tell Claude: "Start the feature workflow for <feature description>" — it will spawn the `feature-orchestrator` agent.

## Running workflows in parallel (worktrees)

Multiple feature workflows can run **concurrently**, each in its own git worktree, with no manual git
commands from you. On startup the orchestrator (`feature-orchestrator`, Step 0) derives a **feature
slug** and — unless the run modifies the workflow tooling itself, see below — creates a worktree under
a single **stable parent directory** on a fresh `feat/<slug>` branch:

```
mkdir -p ../ProjectHana-worktrees
git worktree add -b feat/<slug> ../ProjectHana-worktrees/<slug> main
```

All worktrees live under the one `../ProjectHana-worktrees/` parent — **not** scattered as
`../ProjectHana-<slug>` siblings. That keeps a single directory authorizable once (see "Directory
authorization" below) so no per-worktree access prompt fires when a new parallel workflow starts.

### Directory authorization (one-time, per machine)

A worktree at `../ProjectHana-worktrees/<slug>` sits **outside** the primary checkout, so without
authorization every file read/write/run inside it would trigger a "grant access to this directory"
prompt — once per worktree, per run. To pre-authorize all current and future worktrees at once, the
**parent** dir is added to Claude Code's `permissions.additionalDirectories`. Because the path is
machine-specific and absolute, it lives in the **gitignored** `.claude/settings.local.json` (the
tracked `.claude/settings.json` stays portable):

```jsonc
// .claude/settings.local.json
{
  "permissions": {
    "additionalDirectories": [
      "/Users/<you>/Documents/Code/ProjectHana-worktrees"
    ]
  }
}
```

This is configured once: every worktree created under that parent — now or in the future — is
authorized with no prompt and no per-run config. The grant is **scoped to the worktrees parent only**,
so it does not expose unrelated sibling repos. (Empirically verified: an agent can read, write, and run
commands inside a fresh worktree under this parent with no directory-access prompt. After editing
`settings.local.json` you may need to reload the Claude Code session for the new entry to take effect.)

**Migrating worktrees that were created under the old scheme.** Worktrees made before this change live
at `../ProjectHana-<slug>` (outside the authorized parent) and will keep prompting. To bring an existing
worktree under the authorization without losing work, either (a) finish/tear it down and let its next
run be created under the new parent, or (b) relocate it in place:

```
git -C <primary-checkout> worktree move ../ProjectHana-<slug> ../ProjectHana-worktrees/<slug>
```

(Alternatively, add the specific old sibling path to `additionalDirectories` as a stopgap until it is
torn down.)

### Slug-based isolation

The orchestrator exports `HANA_FEATURE_SLUG=<slug>`, the single shared id that isolates everything:

| Concern        | Isolation mechanism                                                          |
|----------------|------------------------------------------------------------------------------|
| `.workflow/` live state | `feature.md`, `stories.md`, `log.md`, `stories/` are gitignored — each worktree owns its own copy. Only `archive/` + this README are tracked. |
| Branches       | `story/<slug>/<NNN>-…` and `chore/<slug>/…` (see `implement-story`, `merge-pr`). |
| Builds         | `just`'s `wt` var (from `HANA_FEATURE_SLUG`) suffixes DerivedData and `/tmp` output; `sim`/`HANA_SIM_NAME` picks a per-worktree simulator. Empty slug = legacy single-checkout paths. |
| Telemetry      | All worktrees write to the **one** sink in the primary checkout (`scripts/agent-log.sh` resolves it via `git rev-parse --git-common-dir`), each record tagged with the slug. `just telemetry --by-feature` breaks it down. |

To launch two features at once, just tell Claude to start two workflows with different descriptions;
each gets a distinct slug and worktree. On successful completion the orchestrator (Step 11) removes its
own per-slug worktree (`../ProjectHana-worktrees/<slug>`) and prunes its branch, leaving the primary
checkout clean. The shared `../ProjectHana-worktrees/` parent stays in place (and stays authorized) for
future runs.

**Meta / tooling runs (opt-out):** a run that edits the workflow tooling itself (`.claude/agents/`,
`justfile`, `.gitignore`, `scripts/`, this README) runs **in the primary checkout** on a `feat/<slug>`
branch without a worktree — a worktree would carry stale committed copies of the very files being
changed. The slug, branch namespacing, build isolation, and telemetry tagging still apply.
