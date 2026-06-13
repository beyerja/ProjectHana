# Feature: just recipes for agentic workflow commands

## Goal

Add `just` recipes that agents can call to perform common dev tasks — telemetry
analysis, simulator build/install, and simulator utilities — so agent files
reference stable, short recipe names instead of duplicating long shell commands.

## Acceptance Criteria

- [ ] `just telemetry` parses `.workflow/telemetry/agents-*.jsonl` and prints a
  summary table (agent, runs, avg duration, avg est tokens, retries) to stdout.
- [ ] `just build-sim` builds the app for the iOS Simulator (iPhone 17) and
  prints the derived data path or app bundle path on success.
- [ ] `just install-sim` depends on `build-sim` and then installs the built app
  to the booted simulator via `xcrun simctl install booted <APP>`. Running
  `just install-sim` alone triggers the full build + install sequence.
- [ ] `just boot-sim` boots the iPhone 17 simulator (no-op if already booted).
- [ ] `just launch-sim` launches the installed app on the booted simulator.
- [ ] `just screenshot-sim <path>` takes a screenshot of the booted simulator
  and saves it to `<path>`. Includes a debug/verification step so failures are
  surfaced clearly (not silently ignored).
- [ ] `evaluate-workflow.md` is updated to reference `just telemetry` instead of
  inline JSONL parsing shell commands.
- [ ] `verify-story.md` is updated to reference `just build-sim`, `just install-sim`,
  `just boot-sim`, `just launch-sim`, and `just screenshot-sim` for the
  Visual Verification steps.
- [ ] `verify-feature.md` is updated to reference the same just recipes for its
  Visual Verification steps.
- [ ] All new recipes are documented with a brief comment in `justfile`.

## Constraints

- `build-sim` and `install-sim` must remain independently callable (dependency
  via justfile `install-sim: build-sim`, not by inlining the build commands).
- `screenshot-sim` must accept the output path as an argument; it should echo
  a confirmation line and exit non-zero on failure so callers detect errors.
- The `telemetry` recipe must work even when no JSONL files exist (graceful
  empty output, not an error).
- All recipes must set `DEVELOPER_DIR` and extend `PATH` with nix-profile the
  same way the existing `test` and `build-mac` recipes do (or rely on the
  top-level `export` directives already in the justfile).
- No app source code changes.

## Out of Scope

- Automated screenshot diffing or regression detection.
- Recipes for building/running the Mac Catalyst target (those already exist:
  `build-mac`, `install`).
- Anything beyond the six new just recipes and the three agent file updates.
