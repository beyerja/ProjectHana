# Story 002 — Bake the `ui-walkthrough` driver into the verify agents

## Title
Make `just ui-walkthrough` the default, issue-hunting verification in verify-story
and verify-feature

## Goal
Wire the navigate-and-inspect driver into the workflow's verification agents so every
future view-touching story/feature is verified by *navigating* the app and inspecting
per-step screenshots **and** accessibility dumps — replacing the single-static-screenshot
check — and so verification actively hunts for concrete bug classes. Independently
testable: the edited agent files clearly instruct the new flow, name the bug classes,
and define a sim-unavailable fallback.

## Scope (AC1, AC2, AC3)
- **AC1 — `.claude/agents/verify-story.md`:** Any story touching `Hanahuac/Views/**`
  (user-visible) is verified by authoring a focused action script and running
  `just ui-walkthrough`, then inspecting per-step **screenshots AND accessibility
  dumps** — not one static screenshot. This becomes the **default** for view-touching
  stories (not gated solely on an opt-in `## Visual Verification` section). Keep a
  sensible fallback for environments where the simulator is unavailable.
- **AC2 — `.claude/agents/verify-feature.md`:** Run a broader multi-screen walkthrough
  across the feature's affected flows (navigate + inspect dumps), replacing the single
  end-to-end screenshot check.
- **AC3 — active issue hunting (both agents):** Explicitly direct the verifier to look
  for: an **empty accessibility tree = crash/app-gone**; English/untranslated text
  while the UI is in another language; duplicated / missing / obscured / overlapping
  controls. Fail and loop back when found — not merely confirm "matches the spec."

## Acceptance Criteria
- [ ] `verify-story.md` makes `just ui-walkthrough` (script authoring + per-step
      screenshot + accessibility-dump inspection) the default verification for
      view-touching stories, not gated only on an opt-in section, with a
      sim-unavailable fallback.
- [ ] `verify-feature.md` runs a multi-screen driver walkthrough across affected flows
      instead of a single static end-to-end screenshot.
- [ ] Both agents enumerate the concrete bug classes (empty a11y tree = crash,
      untranslated text, duplicated/missing/obscured/overlapping controls) and instruct
      failing + looping back on detection.
- [ ] Changes are documentation/agent-definition edits only (no app code), consistent
      with existing agent file structure.

## Dependencies
Independent of Story 001 (agent-doc edits only). Ordered before Story 003 per the
feature sequencing constraint so the zoom fix is verified by the new mechanism.
Story 003 must use `just ui-walkthrough` + the new `pinch` action regardless of any
agent-definition caching.

## Notes
- Read/Grep/Glob over shell; allowlistable Bash shapes only.
- These are workflow-tooling edits → in-place run on the feature branch (no worktree).
