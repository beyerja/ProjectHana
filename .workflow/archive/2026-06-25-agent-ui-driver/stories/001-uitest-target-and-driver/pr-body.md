## Goal

Create the reusable foundation for the agent UI-driver feature: a new XCUITest target
(`HanahuacUITests`) containing a single **generic, data-driven** driver. The driver reads a JSON
action script and, after every step, emits a screenshot plus a structured accessibility-element dump
to a predictable run directory. This is the abstraction the rest of the feature plugs into, and it
ships first so it builds and runs on its own.

## Changes

- Declare a new `HanahuacUITests` target (`bundle.ui-testing`, platform iOS, deployment target
  matching the app) in `project.yml`, depending on the `Hanahuac` app target, and add it to the
  `Hanahuac` scheme's `test` action. Matches the established target style (settings.base block,
  `SUPPORTS_MACCATALYST`, `SWIFT_VERSION`) and the `HanahuacTests` target shape.
- Regenerate `Hanahuac.xcodeproj` with `just generate` (no manual pbxproj edits).
- Add a single generic, data-driven XCUITest driver that reads an action script from
  `HANA_UI_SCRIPT_PATH` / `HANA_UI_SCRIPT` (or a `.workflow/` JSON file) — not a hardcoded
  one-off navigation path.
- Implement the supported action set decoded from the script: `tap` (by accessibility label or
  identifier), `typeText`, `mapTap` (normalized x,y coordinate), `swipe`/`scroll`, `wait`,
  `dumpTree`, and `screenshot`.
- After each step write `NNN-step.png` and `NNN-step.json` (element dump: type, label, identifier,
  value, frame) under `.workflow/ui-walkthrough/<run>/`, readable with the Read tool.
- Target elements by accessibility **label** in the absence of identifiers, so the build/run is
  green before story 002 adds identifiers.
- Handle an empty/missing action script gracefully: the driver still launches the app and emits an
  initial dump + screenshot rather than crashing.

## Test plan

- [ ] `just generate` regenerates `Hanahuac.xcodeproj` cleanly with the new target.
- [ ] `HanahuacUITests` builds for the iOS Simulator (`platform=iOS Simulator,name=iPhone 17`, iOS 26.5).
- [ ] Driver runs with a sample action script and writes `NNN-step.png` + `NNN-step.json` per step
      under `.workflow/ui-walkthrough/<run>/`.
- [ ] Driver runs with an empty/missing script and still emits an initial dump + screenshot without
      crashing.
- [ ] Elements are resolved by accessibility label (no dependency on identifiers existing yet).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
