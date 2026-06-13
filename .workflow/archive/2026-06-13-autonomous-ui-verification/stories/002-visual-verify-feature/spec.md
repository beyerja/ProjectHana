# Story 002: Visual Screenshot Verification in verify-feature Agent

## Title

Add autonomous visual end-to-end screenshot verification to the `verify-feature` agent.

## Goal

After all stories are merged, the `verify-feature` agent should perform a final
visual sanity check of the feature end-to-end by taking a screenshot on the iOS
Simulator and inspecting it against the feature's acceptance criteria.

## Acceptance Criteria

1. `verify-feature.md` has a visual verification step that runs after the test suite.
2. The step takes a screenshot (reusing simulator if already booted) and saves it to
   `.workflow/screenshots/feature-verify.png`.
3. The agent uses Claude's vision to inspect the screenshot against the feature's
   visual acceptance criteria (from `.workflow/feature.md`).
4. If the screenshot confirms all visual criteria: continues to STATUS: DONE.
5. If any visual criterion fails: lists the failed criterion and the responsible story
   in the STATUS: FAILED output, so the story loop can retry that story.
6. `.workflow/screenshots/` is gitignored.

## Notes

- This story depends on 001 (verify-story visual verification) being done first, so
  the verify-story agent already sets up the simulator reliably.
- The feature-level visual check is a higher-level smoke test, not a replacement for
  per-story verification.
