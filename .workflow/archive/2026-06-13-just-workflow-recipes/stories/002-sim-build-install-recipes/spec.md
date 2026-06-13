# Story 002: just build-sim and install-sim recipes

## Goal

Add `just build-sim` and `just install-sim` recipes so agents can build and
install the app to the iOS Simulator with short, stable recipe names instead
of duplicating long `xcodebuild` invocations.

## Acceptance Criteria

- [ ] `just build-sim` is defined in `justfile`. It builds the ProjectHana app
  for the iOS Simulator (iPhone 17 destination) using `xcodebuild build`, with
  derived data at a stable path (e.g. `/tmp/ProjectHana-sim-build`). On
  success it prints the path to the built `.app` bundle.
- [ ] `just install-sim` is defined in `justfile` and declares `build-sim` as a
  dependency (i.e. `install-sim: build-sim`). It then runs
  `xcrun simctl install booted <APP>` where `<APP>` is the `.app` bundle
  produced by `build-sim`.
- [ ] Running `just install-sim` alone triggers the full build + install
  sequence without requiring a separate prior `just build-sim` call.
- [ ] Running `just build-sim` alone only builds (does not install).
- [ ] Both recipes are accompanied by brief comments in `justfile`.
- [ ] The recipes inherit the top-level `export DEVELOPER_DIR` and `export PATH`
  from the justfile (no duplication needed inside the recipes).
