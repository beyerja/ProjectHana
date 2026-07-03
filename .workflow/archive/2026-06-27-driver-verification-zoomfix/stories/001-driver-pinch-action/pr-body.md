## Goal

Give the `just ui-walkthrough` XCUITest driver a zoom gesture so action scripts can exercise map zoom (in/out). This is pure driver infrastructure and is a prerequisite for verifying the zoom-out fix (Story 003) via the new mechanism. It is independently testable: a script that issues a `pinch` step against the map (or any resolvable element) runs through `just ui-walkthrough` and captures artifacts without erroring.

## Changes

- `HanahuacUITests/UIActionScript.swift`: add a `pinch` case to `UIActionKind`; add a required `scale` field and an optional `velocity` field to `UIActionStep`, decoded coherently with the existing optional fields.
- `HanahuacUITests/UIDriverTests.swift`: dispatch `pinch` via `XCUIElement.pinch(withScale:velocity:)` (scale < 1 = zoom out, scale > 1 = zoom in). Resolve the step element with fallback to the whole app; an unresolvable target is skipped (no crash, no test failure) and per-step artifact capture (screenshot + accessibility dump) continues.
- `.workflow/ui-walkthrough/README.md`: document the new `pinch` action — fields, scale semantics, skip-if-unresolvable behavior, and an example step.

## Test plan

- [ ] `just lint` passes
- [ ] `just test` passes
- [ ] Driver builds
- [ ] A `pinch` step against a resolvable element runs through `just ui-walkthrough` and captures artifacts
- [ ] An unresolvable `pinch` target is skipped without failing the run
