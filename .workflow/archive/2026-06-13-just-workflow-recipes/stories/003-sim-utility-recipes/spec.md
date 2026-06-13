# Story 003: just boot-sim, launch-sim, and screenshot-sim recipes

## Goal

Add `just boot-sim`, `just launch-sim`, and `just screenshot-sim <path>` recipes
so agents can perform common simulator utility operations with stable, short
recipe names that include proper error surfacing.

## Acceptance Criteria

- [ ] `just boot-sim` is defined in `justfile`. It boots the iPhone 17 simulator
  via `xcrun simctl boot "iPhone 17"`, tolerating the "already booted" error
  gracefully (exit 0 in that case).
- [ ] `just launch-sim` is defined in `justfile`. It launches the app with bundle
  ID `com.private.ProjectHana` via `xcrun simctl launch booted <bundle-id>`.
- [ ] `just screenshot-sim <path>` is defined in `justfile` as a recipe that
  accepts a path argument. It runs `xcrun simctl io booted screenshot <path>`,
  echoes a confirmation line (e.g. `Screenshot saved to <path>`) on success,
  and exits non-zero with a clear error message on failure so callers detect
  errors rather than silently continuing.
- [ ] The screenshot recipe includes a debug/verification step: after capturing,
  it checks that the file exists and is non-empty, printing a diagnostic and
  exiting non-zero if not.
- [ ] All three recipes are accompanied by brief comments in `justfile`.
- [ ] The recipes inherit the top-level `export DEVELOPER_DIR` and `export PATH`
  from the justfile.
