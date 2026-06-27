## Goal

Wire the navigate-and-inspect `just ui-walkthrough` driver into the workflow's verification agents so every future view-touching story/feature is verified by *navigating* the app and inspecting per-step screenshots **and** accessibility dumps — replacing the single-static-screenshot check — and so verification actively hunts for concrete bug classes.

Documentation / agent-definition edits only (`.claude/agents/verify-story.md` and `.claude/agents/verify-feature.md`). No app code changes.

## Changes

- **AC1 — `verify-story.md`:** Authoring a focused action script and running `just ui-walkthrough` (per-step screenshots **and** accessibility dumps) is now the **default** verification for any story touching `Hanahuac/Views/**`, no longer gated solely on an opt-in `## Visual Verification` section. Keeps a sensible fallback for environments where the simulator is unavailable.
- **AC2 — `verify-feature.md`:** Runs a broader multi-screen walkthrough across the feature's affected flows (navigate + inspect dumps), replacing the single static end-to-end screenshot check.
- **AC3 — active issue hunting (both agents):** Both agents now explicitly enumerate the concrete bug classes to hunt for — an empty accessibility tree = crash/app-gone; English/untranslated text while the UI is in another language; duplicated / missing / obscured / overlapping controls — and instruct the verifier to FAIL and loop back on detection rather than merely confirming "matches the spec."

## Test plan

- [ ] `verify-story.md` makes `just ui-walkthrough` (script authoring + per-step screenshot + accessibility-dump inspection) the default for view-touching stories, not gated only on an opt-in section, with a sim-unavailable fallback.
- [ ] `verify-feature.md` runs a multi-screen driver walkthrough across affected flows instead of a single static end-to-end screenshot.
- [ ] Both agents enumerate the concrete bug classes and instruct failing + looping back on detection.
- [ ] Changes are documentation/agent-definition edits only (no app code), consistent with existing agent file structure.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
