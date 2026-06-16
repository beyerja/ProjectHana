# Feature: Worktree-parallel feature workflows

## Goal

Adjust the feature workflow and its agents so that multiple feature workflows can run
**in parallel**, each in its own git worktree, without colliding on workflow state, branch
names, build artifacts, or telemetry. The user must not have to perform any manual git or
worktree commands — the orchestrator creates and tears down its own worktree automatically.

## Context (current state)

- Entry point: `.claude/agents/feature_orchestrator.md` → spawns `clarify-feature`, `break-stories`,
  `assess-project-health`, then per-story `story-workflow` (→ `break-tasks`, `implement-story`,
  `create-pr`, `wait-for-ci`, `review-pr`, `merge-pr`, `verify-story`), then `verify-feature`,
  `evaluate-workflow`, `archive-workflow`.
- State lives under `.workflow/` (currently single-tenant): `feature.md`, `stories.md`, `log.md`,
  `stories/<NNN>-<slug>/{spec,tasks,status,pr,log}.md`. Only `archive/<date>-<slug>/…` and `README.md`
  are tracked in git today; live working state is effectively single-workflow.
- Branches are hardcoded `story/<story-id>` in `implement-story.md` (e.g. `story/001-…`) — collides
  across parallel features.
- Builds (`justfile`) use shared, hardcoded paths: `just test` uses default DerivedData and the named
  `iPhone 17` simulator; `build-sim`/`install` use `/tmp/Hanahuac-sim-build`; `build-mac`/`install` use
  `/tmp/Hanahuac-mac-build`. Parallel builds stomp each other.
- Telemetry is gitignored (`.workflow/telemetry/*.jsonl`), written via `just log` → `scripts/agent-log.sh`,
  summarized by `scripts/telemetry-summary.py` (`just telemetry` / `telemetry-history`). `evaluate-workflow`
  Phase 2b reads cross-run history.

## Confirmed design decisions

1. **Workflow state isolation** — gitignore the `.workflow/` live working set (`feature.md`, `stories.md`,
   `log.md`, `stories/`); keep only the timestamp-slugged `archive/` and `README.md` tracked. Each worktree
   then owns its live state with zero cross-feature merge conflicts; the archive remains the durable,
   collision-free record (already namespaced by date+slug).
2. **Branch namespacing** — story/chore branches are namespaced by feature slug so two parallel features
   never produce the same branch name. Exact scheme at implementer's discretion (e.g. `story/<slug>/<NNN>-…`).
3. **Automated worktree lifecycle** — the orchestrator, on startup, derives a feature slug and creates a
   dedicated worktree for the run (no manual user action). On successful completion (after archive +
   closing-artifact commit/merge) it removes its own worktree and prunes the branch. The primary checkout
   is never left in a detached or dirty state by this.
4. **Build isolation (in scope)** — `just` build/test recipes must be parameterized per worktree so
   parallel runs don't collide: per-worktree DerivedData path and a unique simulator destination (cloned
   or per-worktree-named), plus per-worktree `/tmp` build output dirs. Existing single-checkout usage must
   keep working with sensible defaults.
5. **Shared telemetry sink** — all worktrees write to ONE telemetry sink in the primary checkout (not a
   per-worktree copy), with each record tagged by feature slug / worktree id so `telemetry`,
   `telemetry-history`, and `evaluate-workflow` aggregate across parallel and historical runs correctly.

## Acceptance Criteria

- [ ] The orchestrator automatically creates a git worktree for a feature run and removes it on completion;
      the user runs no manual `git worktree` / branch commands.
- [ ] Two feature workflows can run concurrently in separate worktrees without colliding on `.workflow/`
      live state, branch names, build artifacts/DerivedData/simulator, or the telemetry sink.
- [ ] `.workflow/` live working state (feature.md, stories.md, log.md, stories/) is gitignored; only
      `archive/` and `README.md` remain tracked. Archiving still produces a committed, collision-free record.
- [ ] Story/chore branch names are namespaced per feature so parallel features cannot collide.
- [ ] `just test` and the build recipes accept per-worktree isolation (DerivedData, simulator, /tmp output)
      and still work with defaults in a plain single checkout.
- [ ] Telemetry from all worktrees lands in the single shared sink, tagged per feature/worktree; `just
      telemetry` / `telemetry-history` and `evaluate-workflow` Phase 2b still aggregate correctly.
- [ ] All agent files that assume a single checkout / single-tenant `.workflow/` are updated to be
      worktree-aware (no hardcoded absolute paths, no assumption of running in the primary checkout).
- [ ] `.workflow/README.md` documents how to launch parallel worktree workflows.

## Constraints

- Follow the project convention: agents prefer Read/Grep/Glob over shell `cat`/`ls`/`find`/`grep`;
  reserve Bash for side-effecting tooling (`git`, `gh`, `just`, `xcodebuild`).
- Use the existing `just` + flake + direnv environment; never hardcode `/nix` paths or manual PATH/env.
- Do not break the existing single-checkout (non-parallel) workflow — it must remain the simple default.
- macOS, single developer; worktrees live in a sibling directory (not nested inside the primary checkout).

## Out of Scope

- A general job scheduler / queue for workflows (this only enables manual parallel launches).
- Cross-worktree locking beyond what's needed to avoid the collisions above.
- Changing the underlying app (Hanahuac) functionality.
