# Feature: Agent-drivable UI walkthrough (XCUITest driver)

## Goal

Give an agent (Claude) a reusable, autonomous way to **launch the Hanahuac app, navigate
through it, and inspect what is on screen** — so the agent can experience and verify the full
user experience, not just read code. This closes the gap left by the prior screenshot-only
"autonomous-ui-verification" work, which could *see* a screen but could not *drive* the UI
(tap / type / swipe / select a country on the map).

## Chosen approach (decided with the user — clarification already complete)

An **XCUITest-based UI driver** running against the **iOS Simulator**, delivered as a
**reusable committed capability** (UI-test target + `just` recipes + helper script), usable by
the main session and by future workflow sub-agents (e.g. `verify-story`, `verify-feature`).

The driver reads an **action script** (a sequence of steps) and executes it against the real
iOS app, emitting after **every step** both:
- a **screenshot** (PNG), and
- a **structured accessibility-element dump** (role/type, label, identifier, value, frame) of
  the current screen.

Supported actions (minimum viable set): `tap <label-or-identifier>`, `typeText`,
`tap map at normalized (x,y)` (for the tap-a-country map quiz), `swipe`/`scroll`, `wait`, and
`dumpTree` / `screenshot`. The action script is supplied to the test via an environment variable
or a JSON file under `.workflow/` so no recompile is needed to change the sequence — the loop is
**write action script → run driver → read screenshot + element tree → decide next actions**.

To make element targeting reliable, add **accessibility identifiers** to the key interactive
views (home rows, settings entry, quiz controls, map). Keep this change minimal and additive.

## Acceptance Criteria

- [ ] A UI-test target (XCUITest) exists in `Hanahuac.xcodeproj` and builds for the iOS Simulator.
- [ ] A generic, data-driven driver test reads an action script (env var or `.workflow/` JSON
      file) and executes the supported actions in order — it is NOT a hardcoded one-off path.
- [ ] After each step the driver writes a screenshot AND an accessibility-element dump to a
      predictable location (e.g. `.workflow/ui-walkthrough/<run>/NNN-step.png` + `NNN-step.json`),
      so an agent can read them with the Read tool.
- [ ] `just` recipes expose the capability end-to-end (build + run the driver against the booted
      simulator and collect artifacts), matching the existing recipe style (worktree-aware,
      allowlistable shapes, tools via direnv/flake).
- [ ] At least the supported action set works: tap by accessibility label/identifier, type text,
      tap the map at a normalized coordinate, swipe/scroll, and dump the element tree + screenshot.
- [ ] A demonstrated end-to-end walkthrough exists proving navigation across multiple real
      screens (e.g. Home → open a quiz mode → interact → Settings), with the resulting
      screenshots + element dumps as evidence.
- [ ] Accessibility identifiers are added to the key interactive views the driver needs to target,
      without altering visible behavior or copy.
- [ ] Documentation: a short note (README/justfile comments) explaining how to author an action
      script and run the driver, so future sub-agents can reuse it.

## Constraints

- **No new external tooling and no host permission grants.** Confirmed on this machine: no
  Homebrew, no `idb`/`idb_companion`, no `cliclick`; `xcrun simctl` has no tap subcommand; and
  macOS Accessibility / System Events automation is **TCC-blocked** (System Events times out
  `-1712`). The solution must rely only on Xcode/XCUITest + `xcrun simctl`, which need neither an
  install nor a manual permission grant.
- **iOS Simulator only** for this feature (primary app target; most faithful to the real UX).
  Mac Catalyst driving is explicitly out of scope here.
- Environment facts to reuse (don't re-probe): Xcode 26.5; iPhone 17 simulator on iOS 26.5 is the
  default destination (matches `justfile` `sim` default); bundle id `com.hanahuac.app`.
- Follow repo conventions: Read/Grep/Glob over shell inspection; allowlistable Bash shapes
  (no `cd &&`, no heredocs/`$(…)`, no poll loops); recipes go through `just` + direnv/flake;
  per-worktree build isolation honored.
- **Workflow-tooling guard:** this feature touches `justfile` and `scripts/` (workflow tooling),
  so per the orchestrator Step-0 guard it should run **in the primary checkout** (no worktree),
  on a feature branch. The XCUITest target + accessibility identifiers are app-code changes that
  land in the same branch.
- Performance reality: each driver run is a compiled `xcodebuild test` cycle (~tens of seconds);
  the capability is script-an-action → run → inspect, not live frame-by-frame. This is acceptable
  and should be documented, not "fixed."

## Out of Scope

- Live, frame-by-frame interactive tapping (Option B) — would require a manual macOS Accessibility
  permission grant; explicitly declined.
- Installing `idb`/`idb_companion` or any third-party automation binary (Option C).
- Mac Catalyst / macOS-native driving.
- Wiring the driver into the blocking PR CI (it may be slow); if any CI integration is desired it
  should follow the repo's "slow checks run async, not per-PR" convention. Default: not gating CI.
- A full automated visual-regression / screenshot-diff system — this feature is about *driving and
  inspecting*, not pixel-diff assertions.
