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
   parallel"). **First check whether this slug's worktree already exists** — an earlier attempt may have
   been interrupted, leaving the worktree, branch, and a partially-written `.workflow/` behind.
   `git worktree add -b` *fails* against an existing path/branch, so resume instead of recreating:
   ```sh
   slug=<feature-slug>
   mkdir -p "../ProjectHana-worktrees"
   if git worktree list --porcelain | grep -q "ProjectHana-worktrees/$slug"; then
     :                                            # RESUME: worktree already exists, reuse it as-is
   else
     git worktree add -b "feat/$slug" "../ProjectHana-worktrees/$slug" main
   fi
   direnv allow "../ProjectHana-worktrees/$slug"   # a fresh worktree's .envrc is unauthorized; without
                                                   # this the first `just` recipe dies with "direnv: .envrc is blocked"
   ```
   When resuming an existing worktree, **read its `.workflow/log.md` first** to learn how far the prior
   attempt got, and treat each phase as idempotent: skip any step whose artifact is already present and
   complete (e.g. don't re-spawn `clarify-feature` if `.workflow/feature.md` already holds an
   authoritative spec; don't re-create a story whose `status.md` reads done). Pick up at the first
   incomplete step. Record `RESUMED existing worktree` and the resume point in `.workflow/log.md`.
   Export `HANA_FEATURE_SLUG="$slug"` for every sub-agent so branch names, `just` build paths, and
   telemetry are isolated. The shared telemetry sink still resolves to the primary checkout
   (see `scripts/agent-log.sh`), so cross-run aggregation keeps working. (When REUSING a pre-existing
   worktree, still run `direnv allow` once in it before the first `just` call for the same reason.)

Then run the following steps in order (from the worktree, if one was created), spawning a dedicated
sub-agent for each:

1. **Clarify** — spawn `clarify-feature` agent. **Skip it** only when the request already supplies
   unambiguous goal + acceptance criteria + root cause (e.g. a bug report that names the offending view
   and the established fix pattern, or a follow-up to a merged PR). In that case write `.workflow/feature.md`
   directly and record *why* clarification was unnecessary in `.workflow/log.md`. When in doubt, spawn it.
2. **Break stories** — spawn `break-stories` agent
3. **Assess health** — spawn `assess-project-health` agent (may prepend setup stories)
4. **Story loop** — for each story in `.workflow/stories.md` where status ≠ done:
   - Spawn `story-workflow` agent with the story's directory path
   - If the story comes back FAILED, re-run it (pass prior failure context)
5. **Create PR** — **first check whether a feature PR is even needed.** This repo's convention is that
   each *story* PR targets `main` directly; no long-lived `feat/<slug>` base branch is used. If
   `git ls-remote origin feat/<slug>` is empty and every story already squash-merged to `main`, then a
   feature PR would be empty — skip PR creation, record *why* in `.workflow/log.md`, and proceed to the
   cross-feature collision re-verification below (which still matters). Only when a real feature branch
   carries unmerged commits do the integrate-and-open steps that follow apply:
   first **integrate the latest `main`** into the feature branch (`git fetch origin`
   then `git merge origin/main`), because `main` may have advanced since the worktree was cut — long
   runs routinely see it move *several times* mid-flight. Resolve conflicts (regenerate
   `Hanahuac.xcodeproj` rather than hand-merging the pbxproj; integrate with — don't duplicate —
   infra a newer `main` PR already added, e.g. the versioned-schema/migration files), then re-run
   `just lint` + `just test` and fix any new call sites a `main`-side change introduced against your
   new APIs.
   - **Cross-feature collisions are not just file conflicts.** A clean text merge can still leave a
     *semantic* regression that no conflict marker flags. The classic case: your feature added new
     localization keys (a new namespace), while a `main`-side feature independently added a *new
     locale* — the merge silently produces a locale that is missing exactly your new keys. The static
     l10n gate hardcodes its locale list (a brand-new locale is invisible to it) and the runtime
     completeness XCTest degrades-to-pass in CI (the ODR pack bundle isn't mounted, so it reads
     empty). So after integrating `main`, **re-verify l10n completeness against every on-disk
     `Hanahuac/*.lproj`, not just the gate's hardcoded list**: diff each locale's keys against the
     base locale and translate any keys a new locale is missing because of your namespace. Apply the
     same "did main add a new X that interacts with my new keys?" check to other registries
     (asset catalogs, schema entities, feature flags).
   Only then spawn `create-pr` to push and open the PR against main (skip if one already
   exists). A stale-base PR shows `mergeState: DIRTY` with no checks — that means re-integrate `main`.
6. **Wait for CI** — spawn `wait-for-ci` agent with the PR number from step 5
   - STATUS: FAIL → fix the failure (spawn `implement-story` on the responsible story with CI failure as context), push, then repeat from step 6. NOTE: CI runs against a **clean** store/build, so it catches failures a stale local simulator masks (e.g. SwiftData container-init aborts) — reproduce those locally with `xcrun simctl erase` before assuming a fix works.
   - STATUS: PASS → continue
   - If `main` advances again while CI runs and the PR goes `DIRTY`, re-integrate `main` (step 5) and re-push.
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

**Emit allowlistable command shapes** (full rules in CLAUDE.md → "Emit allowlistable command shapes").
The headline for orchestration: **avoid `cd`-prefixed compound Bash.** A `cd /abs/path && <cmd>` block
can't be safely allowlisted and gets prompted every time (it was the single most-prompted signature in
evaluation telemetry, and the top offenders are `cd ../ProjectHana-worktrees/<slug> && …` from parallel
worktree runs). Run side-effecting tools at a path instead: `git -C <worktree> …`, `gh -R <owner/repo>
…`, and `just -f <worktree>/justfile …` (the recipes are already worktree-aware). The worktrees parent
is pre-authorized (Step 0), so you can read/write/run inside `../ProjectHana-worktrees/<slug>` directly
with no `cd` and no prompt. Reserve `cd` for the rare tool with no path flag. Likewise: commit with
`git commit -F <file>` (message written via the Write tool), open PRs with `gh pr create --body-file`,
and wait on CI with `gh pr checks <n> --watch --fail-fast` — never heredocs, `$(…)`, or hand-rolled
poll loops.

Output STATUS: DONE when the feature is verified and the workflow has been evaluated and improved.
