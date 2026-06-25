# 001 — UI-test target & generic data-driven driver

## Title
Add an XCUITest target with a generic, action-script-driven UI driver

## Goal
Create the reusable foundation: a new XCUITest target (`HanahuacUITests`) wired into
`project.yml` (regenerated via `just generate`, never hand-edited pbxproj) containing a single
**generic, data-driven** driver test. The driver reads an **action script** (a JSON sequence of
steps) from an environment variable or a `.workflow/` JSON file, executes the supported actions in
order against the launched Hanahuac app, and after **every step** emits a screenshot (PNG) and a
structured accessibility-element dump (JSON) to a predictable run directory. This is the
abstraction the rest of the feature plugs into — it ships first and must build and run on its own,
targeting elements by accessibility **label** (so it works before story 002 adds identifiers).

## Acceptance Criteria
- [ ] `project.yml` declares a new `HanahuacUITests` target of type `bundle.ui-testing`
      (platform iOS, deploymentTarget matching the app), depending on the `Hanahuac` app target,
      and the `Hanahuac` scheme's `test` action includes it.
- [ ] `Hanahuac.xcodeproj` is regenerated with `just generate` (no manual pbxproj edits) and the
      new target builds for the iOS Simulator (`platform=iOS Simulator,name=iPhone 17`, iOS 26.5).
- [ ] A single generic driver test reads an action script from an env var (e.g.
      `HANA_UI_SCRIPT`/`HANA_UI_SCRIPT_PATH`) or a `.workflow/` JSON file — it is NOT a hardcoded
      one-off navigation path.
- [ ] The supported action set is implemented and decoded from the script: `tap`
      (by accessibility label or identifier), `typeText`, `mapTap` (normalized x,y coordinate),
      `swipe`/`scroll`, `wait`, `dumpTree`, and `screenshot`.
- [ ] After each step the driver writes `NNN-step.png` and `NNN-step.json` (element dump: type,
      label, identifier, value, frame) under a predictable run dir
      (`.workflow/ui-walkthrough/<run>/`), readable with the Read tool.
- [ ] The driver targets elements by accessibility label in the absence of identifiers, so the
      build/run is green before story 002 lands (no dependency on identifiers existing yet).
- [ ] An empty/missing action script is handled gracefully (driver still launches the app and
      emits an initial dump+screenshot rather than crashing).

## Notes / Constraints
- XCUITest + `xcrun simctl` only — no idb/brew/cliclick, no host permission grants.
- Match the established `project.yml` target style (settings.base block, SUPPORTS_MACCATALYST,
  SWIFT_VERSION) and the `HanahuacTests` target shape.
