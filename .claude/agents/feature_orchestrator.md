---
name: feature-orchestrator
description: Orchestrate the full feature lifecycle from clarification through story delivery, final verification, and workflow self-evaluation
---

Manage all state under `.workflow/`. Create the directory on first run. Append every phase transition to `.workflow/log.md`.

## Step 0 — Worktree setup (automatic isolation; no manual user action)

So multiple feature workflows can run in parallel without colliding, each run gets its own git
worktree. Do this before any other step:

1. Derive a feature slug from the feature request (lowercase, hyphenated, e.g.
   `worktree-parallel-workflows`). This single slug is the shared id for the worktree, the branch
   namespace (`story/<slug>/…`, `chore/<slug>/…`), build isolation (`HANA_FEATURE_SLUG` → `just`'s
   `wt`), and telemetry tagging — never re-derive it ad hoc elsewhere.
2. **Guard / opt-out.** Skip worktree creation and run in the current checkout when the user
   explicitly says so, or when the run *modifies the workflow tooling itself* (the agents in
   `.claude/agents/`, `justfile`, `.gitignore`, `scripts/`, `.workflow/README.md`) — those changes
   must land in the primary checkout because the worktree would carry stale committed copies. In that
   case still export `HANA_FEATURE_SLUG` and use a feature branch, but do not create a worktree.
   Record the choice (worktree vs. in-place) in `.workflow/log.md`.
3. Otherwise create a worktree under the **stable worktrees parent** on a fresh feature branch and run
   all subsequent steps from inside it. All parallel worktrees live under one parent dir
   (`../ProjectHana-worktrees/<slug>`) — never as scattered `../ProjectHana-<slug>` siblings — so a
   single `permissions.additionalDirectories` grant pre-authorizes every current and future worktree
   and no directory-access prompt fires per run (see `.workflow/README.md` → "Running workflows in
   parallel"):
   ```sh
   slug=<feature-slug>
   mkdir -p "../ProjectHana-worktrees"
   git worktree add -b "feat/$slug" "../ProjectHana-worktrees/$slug" main
   direnv allow "../ProjectHana-worktrees/$slug"   # a fresh worktree's .envrc is unauthorized; without
                                                   # this the first `just` recipe dies with "direnv: .envrc is blocked"
   ```
   Export `HANA_FEATURE_SLUG="$slug"` for every sub-agent so branch names, `just` build paths, and
   telemetry are isolated. The shared telemetry sink still resolves to the primary checkout
   (see `scripts/agent-log.sh`), so cross-run aggregation keeps working. (When REUSING a pre-existing
   worktree, still run `direnv allow` once in it before the first `just` call for the same reason.)

Then run the following steps in order (from the worktree, if one was created), spawning a dedicated
sub-agent for each:

1. **Clarify** — spawn `clarify-feature` agent
2. **Break stories** — spawn `break-stories` agent
3. **Assess health** — spawn `assess-project-health` agent (may prepend setup stories)
4. **Story loop** — for each story in `.workflow/stories.md` where status ≠ done:
   - Spawn `story-workflow` agent with the story's directory path
   - If the story comes back FAILED, re-run it (pass prior failure context)
5. **Create PR** — spawn `create-pr` agent to push the current branch and open a PR against main with a description derived from `.workflow/feature.md`. Skip if a PR for this branch already exists.
6. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 5
   - STATUS: FAIL → fix the failure (spawn `implement-story` on the responsible story with CI failure as context), push, then repeat from step 6
   - STATUS: PASS → continue
7. **Verify feature** — spawn `verify-feature` agent
   - STATUS: FAILED → identify responsible story, return to step 4 for that story
   - STATUS: DONE → continue
8. **Evaluate** — spawn `evaluate-workflow` agent
9. **Archive** — spawn `archive-workflow` agent
10. **Commit closing artifacts** — commit and push the archive move **and** any agent-file edits the
    `evaluate-workflow` step applied, via a `chore/<slug>/…` branch + PR (squash-merge once CI is
    green). Then verify `git status --porcelain .workflow` is clean — nothing in `.workflow/` (outside
    the gitignored telemetry sink) may be left as an uncommitted delta.
11. **Worktree teardown** — only if Step 0 created a worktree. After the closing-artifact PR is merged,
    return to the primary checkout and remove this run's worktree and branch so nothing is left behind:
    ```sh
    git -C <primary-checkout> worktree remove "../ProjectHana-worktrees/$slug"
    git -C <primary-checkout> worktree prune
    git -C <primary-checkout> branch -D "feat/$slug" 2>/dev/null || true
    ```
    The shared `../ProjectHana-worktrees` parent dir stays in place (and stays authorized) for future
    runs — only the per-slug subdir is removed. The primary checkout must never be left detached or
    dirty by this. If a worktree was NOT created (in-place/meta run), skip teardown and just confirm
    the working tree is clean.

At each step, note the outcome in `.workflow/log.md`. If a step sends the workflow back, record the reason.

**Avoid `cd`-prefixed compound Bash.** A `cd /abs/path && <cmd>` block can't be safely allowlisted and
gets prompted every time (it was the single most-prompted signature in evaluation telemetry). Run
side-effecting tools at a path instead: `git -C <repo> …`, `gh -R <owner/repo> …`, and `just`
recipes whose paths are already worktree-aware. Reserve `cd` for the rare tool with no path flag.

Output STATUS: DONE when the feature is verified and the workflow has been evaluated and improved.
