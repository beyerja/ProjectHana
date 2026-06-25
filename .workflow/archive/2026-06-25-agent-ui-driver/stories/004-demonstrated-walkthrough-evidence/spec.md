# 004 — Demonstrated end-to-end walkthrough evidence

## Title
Produce a demonstrated multi-screen walkthrough with committed screenshot + element-dump evidence

## Goal
Prove the capability works end-to-end by authoring a real action script that drives a genuine
multi-screen path — **Home → open a quiz mode → interact (tap answer / type / map-tap) →
Settings** — running it via the story-003 `just` recipe, and capturing the resulting per-step
screenshots and accessibility-element dumps under `.workflow/ui-walkthrough/<run>/` as committed
evidence. This is the hard acceptance criterion: a verifiable artifact trail showing the agent
actually navigated across multiple real screens, not just code that could.

## Acceptance Criteria
- [ ] A committed action script (JSON) drives the path Home → open a quiz mode → interact
      (at least one of: tap an answer, type text, tap the map at a normalized coordinate) →
      Settings.
- [ ] The driver run produces, for each step, a `NNN-step.png` screenshot AND a `NNN-step.json`
      element dump under `.workflow/ui-walkthrough/<run>/`, and these artifacts are committed.
- [ ] The evidence demonstrates ALL supported actions across the run collectively: tap by
      label/identifier, typeText, mapTap (normalized coordinate), swipe/scroll, wait,
      dumpTree, screenshot.
- [ ] The screenshots visibly show distinct real screens (Home, a quiz mode, Settings),
      confirming actual cross-screen navigation occurred.
- [ ] A short index/README in the run dir (or appended to the walkthrough README) maps each step
      number to the action performed and the screen reached, so a reviewer can follow the path.

## Notes / Constraints
- Depends on stories 001 (driver), 002 (identifiers for robust targeting), and 003 (the recipe
  to run it and collect artifacts).
- Evidence is the deliverable here; it satisfies the feature's hard "demonstrated end-to-end
  walkthrough" acceptance criterion.
