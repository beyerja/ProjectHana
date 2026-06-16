# Story 003 — Build/test isolation in the justfile

## Goal
Parameterize `just` build/test recipes per worktree so parallel runs don't collide on DerivedData,
simulator destination, or `/tmp` build output — while a plain single checkout keeps working with
sensible defaults.

## Acceptance Criteria
- [ ] `just test` accepts a per-worktree DerivedData path and a unique simulator destination
      (cloned or per-worktree-named); defaults to today's behavior when unset.
- [ ] `build-sim`/`install-sim` use a per-worktree DerivedData and `/tmp` output dir; default
      unchanged for single checkout.
- [ ] `build-mac`/`install` use a per-worktree DerivedData and `/tmp` output dir; default unchanged.
- [ ] Isolation is driven by a single variable (e.g. a worktree/slug id) with empty-default
      fallback to current paths, so no recipe regresses in a plain checkout.
- [ ] `just lint-sh` still passes; recipes remain shellcheck-clean where they use bash.
