# Feature: Pre-authorize parallel worktree directories (no per-worktree access prompts)

## Goal

When feature workflows run in parallel, the orchestrator creates each run's worktree as a sibling
directory of the primary checkout (`../ProjectHana-<slug>`). That path is **outside** Claude Code's
permitted working directory, so every file operation an agent performs inside the worktree triggers a
manual "grant access to this directory" prompt. Eliminate this: agents must be able to operate in any
parallel worktree **without the user having to approve directory access per worktree, per run.** The
fix must be durable (configure once) and require no manual action when new parallel workflows start.

## Context (current state)

- Worktree creation lives in `.claude/agents/feature_orchestrator.md` **Step 0**:
  `git worktree add -b "feat/$slug" "../ProjectHana-$slug" main` — a sibling of the primary checkout.
  Teardown (Step 11) and `.workflow/README.md` reference the same `../ProjectHana-$slug` layout.
- `.claude/settings.json` has **no** `permissions.additionalDirectories` entry, so sibling worktrees
  are not pre-authorized and prompt on every access.
- Two parallel worktrees are live right now and exhibiting the problem:
  `/Users/Private/Documents/Code/ProjectHana-progress-statistics` and
  `/Users/Private/Documents/Code/ProjectHana-river-line-interruptions`.
- This is the primary working dir; `/Users/Private/Documents/Code/ProjectHanaIdeas` is an unrelated
  additional working dir.
- Lesson from the prior worktree feature: isolation/permission claims must be **empirically verified**
  against a real worktree, not assumed — the simulator-isolation gap shipped unverified.

## Recommended approach (confirm in clarify; implementer may adjust if it doesn't actually suppress prompts)

Pre-authorize worktree directories via Claude Code's `permissions.additionalDirectories` rather than
prompting per run. To make a **single** authorization cover all current and future worktrees, give
worktrees a **stable parent directory** instead of scattering them as `../ProjectHana-<slug>` siblings:

- Relocate worktree creation to a dedicated parent, e.g. `../ProjectHana-worktrees/<slug>` (Step 0,
  Step 11, README all updated to match).
- Add that one parent directory to `permissions.additionalDirectories` so every worktree under it is
  authorized with no prompt and no per-run config.
- Machine-specific absolute paths belong in the gitignored `.claude/settings.local.json`; keep the
  tracked `.claude/settings.json` portable. (Implementer to confirm which file actually applies the
  grant to spawned/background sub-agents.)

**Fallback if `additionalDirectories` does not reliably suppress prompts for background sub-agents:**
nest worktrees inside the primary checkout under a gitignored path (e.g. `.worktrees/<slug>`), so they
are inherently within the working directory and need no extra authorization. Pick whichever is verified
to actually stop the prompts.

## Acceptance Criteria

- [ ] An agent can read/write/run files inside a parallel worktree **without any per-worktree directory
      access prompt** — verified empirically against a real worktree, not assumed.
- [ ] The authorization is configured **once** and automatically covers all current and future parallel
      worktrees; starting a new parallel workflow requires no manual access approval.
- [ ] Orchestrator Step 0 (worktree creation), Step 11 (teardown), and `.workflow/README.md` are
      consistent with the chosen worktree location scheme.
- [ ] The two currently-live worktrees (`ProjectHana-progress-statistics`,
      `ProjectHana-river-line-interruptions`) are unblocked by the fix, or the change documents how to
      bring already-created worktrees under the new authorization.
- [ ] Machine-specific absolute paths are not hardcoded into the tracked `.claude/settings.json`
      (use `.claude/settings.local.json` for those); portable settings stay portable.
- [ ] Single-checkout and in-place/meta runs are unaffected.
- [ ] `.workflow/README.md` documents the directory-authorization setup for parallel workflows.

## Constraints

- Follow the project convention: prefer Read/Grep/Glob over shell `cat`/`ls`/`find`/`grep`; reserve Bash
  for side-effecting tooling (`git`, `gh`, `just`, `xcodebuild`).
- Do not weaken the security posture more than necessary — authorize a scoped worktrees parent, not a
  broad directory that would also grant access to unrelated sibling repos.
- This run **modifies workflow tooling** (`.claude/agents/`, `.claude/settings*.json`, `README.md`), so
  per the orchestrator's Step 0 guard it runs **in-place in the primary checkout** (no worktree for this
  run). Still use a `feat/<slug>` branch and `HANA_FEATURE_SLUG`.
- Use the existing `just` + flake + direnv environment; never hardcode `/nix` paths.

## Out of Scope

- Changing the parallel-isolation mechanism itself (branches, build dirs, telemetry) beyond what the
  directory-authorization fix requires.
- The known simulator-contention gap (separate, already-flagged follow-up).
- Any change to the Hanahuac app functionality.
