# Story 001 — Add a `pinch` (zoom) action to the UI driver

## Title
Add a `pinch`/zoom action to the `just ui-walkthrough` XCUITest driver

## Goal
Give the driver a zoom gesture so action scripts can exercise map zoom (in/out).
This is pure driver infrastructure and is a prerequisite for verifying the zoom-out
fix (Story 003) via the new mechanism. It is independently testable: a script that
issues a `pinch` step against the map (or any resolvable element) runs through
`just ui-walkthrough` and captures artifacts without erroring.

## Scope (AC4)
- Extend `HanahuacUITests/UIActionScript.swift`:
  - Add a new `pinch` case to `UIActionType`.
  - Add `scale` (required) and optional `velocity` fields to `UIActionStep`
    (decode coherently with existing optional fields).
- Handle `pinch` in `UIDriverTests` via `XCUIElement.pinch(withScale:velocity:)`
  (scale < 1 = zoom out, scale > 1 = zoom in). Target the resolved element, or
  the map element (consistent with how `mapTap` / `map.tapCountry` resolve the map).
- Unresolvable target is **skipped** (consistent with the other actions); artifact
  capture (screenshot + accessibility dump per step) continues.
- Document the new action (fields, scale semantics, skip-if-unresolvable behavior,
  an example step) in `.workflow/ui-walkthrough/README.md`.

## Acceptance Criteria
- [ ] `UIActionType` has a `pinch` case; `UIActionStep` decodes `scale` (required for
      pinch) and optional `velocity`.
- [ ] `UIDriverTests` performs the pinch via `XCUIElement.pinch(withScale:velocity:)`
      on the resolved/target element; scale<1 zooms out, scale>1 zooms in.
- [ ] An unresolvable pinch target is skipped (no crash/no test failure); per-step
      artifacts continue to be captured.
- [ ] `.workflow/ui-walkthrough/README.md` documents the `pinch` action with scale
      semantics and an example.
- [ ] `just lint` and `just test` pass; the driver builds. Do NOT hand-edit pbxproj
      (project regenerated via `just generate` / xcodegen if a file is added).

## Dependencies
None. This is the first story and unblocks Story 003.

## Notes
- Read/Grep/Glob over shell; allowlistable Bash shapes only.
