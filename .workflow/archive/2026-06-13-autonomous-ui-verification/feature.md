# Feature: Autonomous UI Verification in Story Workflow

## Summary

Add autonomous visual/behavioral verification to the story-workflow agent so that
UI-affecting stories are automatically validated after implementation — without
requiring the user to confirm. The workflow must catch regressions like "code
appears implemented but the visual result is wrong" before stories are marked done.

## Problem

A previous story (map-quiz phase) was supposed to render a semi-transparent color
overlay on a country when a pin was pressed. The implementation looked correct in
code review but the visual effect did not work when tested manually. The story was
marked done without catching this.

## Goal

After each story that could affect UI behavior, the story-workflow agent should:
1. Boot the iOS Simulator (or use an already-running one)
2. Take a screenshot and/or run scripted xcrun simctl interactions
3. Verify the expected visual/behavioral outcome autonomously
4. If verification fails: attempt to diagnose and fix, then re-verify
5. Only block and ask the user if truly stuck after attempting a fix

## Scope

- **In scope:** Any story that touches SwiftUI views, gestures, animations, map
  rendering, overlays, colors, or any other user-visible behavior.
- **Out of scope:** Stories that are purely workflow/tooling/CI changes (no app
  code touched). These may skip the UI verification step.

## Platform

iOS Simulator via `xcrun simctl`. Use whichever simulator is already booted; if
none is booted, boot the default iPhone simulator. This minimizes friction.

## Verification Approach

- Use `xcrun simctl io <device> screenshot <path>` to capture screens.
- Use the `/verify` and `/run` skills where applicable.
- Compare screenshots or inspect UI state programmatically (accessibility
  inspector, or simctl UI dump) to confirm the feature is visible.
- The workflow is fully self-contained; no human confirmation step.

## Acceptance Criteria

1. `story-workflow` agent (or `verify-story` sub-agent) takes a screenshot after
   implementation of any UI story and logs the result.
2. If the screenshot/interaction shows the expected behavior, story is marked done.
3. If not, the agent attempts a fix and re-verifies at least once before escalating.
4. Pure tooling stories explicitly skip the verification step (documented in the
   story or agent logic).
5. The verify-story agent is updated (or created if absent) to encapsulate this
   logic so it can be reused across the workflow.

## Key Files

- `.claude/agents/story-workflow.md` — orchestrator that calls verify-story
- `.claude/agents/verify-story.md` — visual verification sub-agent (update/create)
- `.claude/agents/verify-feature.md` — end-to-end feature verification

## Notes

- The `/verify` skill already exists and does manual-style app verification.
  Leverage it inside the verify-story agent.
- xcrun simctl is available in the Darwin/zsh environment.
- Screenshots should be saved under `.workflow/screenshots/<story-slug>/` for
  traceability.
