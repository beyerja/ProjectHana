# 003 — `just` recipes, helper script & authoring docs

## Title
Expose the driver end-to-end via `just` recipes + helper script + documentation

## Goal
Wrap the XCUITest driver into a reusable, end-to-end `just` capability so the main session and
future workflow sub-agents (`verify-story`, `verify-feature`) can run it without remembering raw
`xcodebuild` invocations. Add a `just` recipe that builds + runs the driver against the booted
simulator with a given action script and collects the artifacts under
`.workflow/ui-walkthrough/<run>/`, plus a small helper script (in `scripts/`) for the glue (run
dir setup, script plumbing via env var/JSON, artifact location echo). Document how to author an
action script and run the driver.

## Acceptance Criteria
- [ ] A `just` recipe (e.g. `ui-walkthrough <script> [run]`) builds the `HanahuacUITests` target
      and runs it against the booted simulator, passing the action script via env var or JSON path,
      and prints the resulting artifact directory.
- [ ] Recipe style matches the existing `justfile`: worktree-aware (`{{sim}}`, `{{sim_dd}}`,
      per-worktree DerivedData), allowlistable command shapes (no `cd &&`, no heredocs/`$(…)` in
      committed recipes, no poll loops), tools via direnv/flake.
- [ ] A committed `scripts/*.sh` helper (shellcheck-clean, passes `just lint-sh`) handles run-dir
      creation and action-script plumbing rather than inline one-offs.
- [ ] Documentation (a short note in `.workflow/ui-walkthrough/README.md` and/or justfile recipe
      comments) explains the action-script JSON schema, the supported actions, where artifacts
      land, and the write-script → run → read-artifacts loop — including the documented
      "compiled test cycle ~tens of seconds, not live frame-by-frame" performance reality.
- [ ] Running the recipe with a trivial script (launch + dump) succeeds and produces a screenshot
      + element dump, proving the wiring (full multi-screen evidence is story 004).
- [ ] `just lint` (swift/py/sh/nix/yaml) stays green.

## Notes / Constraints
- Default: NOT wired into blocking PR CI (out of scope per feature); if any CI hook is added later
  it follows the repo's "slow checks run async, not per-PR" convention.
- Depends on story 001 (the target/driver must exist); identifiers from 002 make the example
  script cleaner but are not required for the wiring to work.
