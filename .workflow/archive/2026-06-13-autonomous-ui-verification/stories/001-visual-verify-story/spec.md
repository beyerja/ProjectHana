# Story 001: Visual Screenshot Verification in verify-story Agent

## Title

Add autonomous visual screenshot verification to the `verify-story` agent for UI-touching stories.

## Goal

After a story is implemented and merged, the `verify-story` agent should automatically
boot the iOS Simulator, install the app, launch it, take one or more screenshots, and
confirm the expected visual behavior is present — without requiring the user to confirm.
If verification fails, the agent should attempt to diagnose and fix the issue, then
re-verify at least once before escalating.

## Acceptance Criteria

1. `verify-story.md` has a "Visual Verification" section that activates when the story
   spec includes a `## Visual Verification` block describing what to look for.
2. When activated, the agent:
   a. Boots a simulator if none is running: `xcrun simctl boot "iPhone 17" 2>/dev/null || true`
   b. Builds and installs the app to the simulator via xcodebuild (same destination as `just test` uses: `platform=iOS Simulator,name=iPhone 17`). Use `just test` as a reference; adapt to a plain build+install via `xcodebuild build -destination 'platform=iOS Simulator,name=iPhone 17'` then install the .app with `xcrun simctl install booted <path>`.
   c. Launches the app: `xcrun simctl launch booted com.private.ProjectHana`
   d. Takes a screenshot: `xcrun simctl io booted screenshot <path>`
   e. Saves the screenshot to `.workflow/screenshots/<story-id>/verify-<N>.png`
3. The agent inspects the screenshot (using Claude's vision) against the expected
   behavior described in the `## Visual Verification` block.
4. If the screenshot confirms the expected behavior: proceeds to mark story done.
5. If not: logs the failure in `<story-dir>/log.md`, attempts a targeted fix, rebuilds,
   re-takes a screenshot, and re-checks. Does this at most 2 times before escalating.
6. Pure tooling stories (no `## Visual Verification` block) skip this step entirely.
7. Screenshots directory `.workflow/screenshots/` is gitignored (large binary files).

## Notes

- There is no `just install-sim` target. The Justfile's `just test` target uses
  `xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 17'`. The
  visual verification step should build and install via xcodebuild directly.
- `just install` is Mac Catalyst only — do not use it for simulator verification.
- The `## Visual Verification` block in a story spec should describe the expected
  screen state in plain English (e.g., "The selected country shows a red semi-transparent
  overlay after tapping a pin").
- Screenshots should be timestamped or sequenced to distinguish re-verify attempts.
