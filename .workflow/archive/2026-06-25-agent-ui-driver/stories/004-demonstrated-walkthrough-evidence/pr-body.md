## Goal

Prove the agent UI driver works end-to-end by authoring a real action script that drives a
genuine multi-screen path — **Home → Multiple Choice quiz → answer → Home → Settings** — and
capturing committed per-step screenshot + accessibility-element-dump evidence. This satisfies the
feature's hard "demonstrated end-to-end walkthrough" acceptance criterion: a verifiable artifact
trail showing the agent actually navigated across multiple real screens, not just code that could.

## Summary of changes

- **Action script** — `.workflow/ui-walkthrough/scripts/full-walkthrough.json` (16 steps) drives the
  real path Home → Multiple Choice quiz → answer → Home → Settings, collectively exercising ALL
  supported driver actions: tap by label/identifier, `typeText`, `mapTap` (normalized coordinate),
  `swipe`/`scroll`, `wait`, `dumpTree`, and `screenshot`.
- **Committed evidence** — per-step artifacts under `.workflow/ui-walkthrough/demo/` (17 step pairs
  `000`–`016`: `NNN-step.png` + `NNN-step.json`) plus a step-index README mapping each step → action
  → screen. A narrow `.gitignore` un-ignore rule keeps the demo dir tracked.
- **Screenshots verified** by reading the PNGs: Home (000/002/012), Multiple Choice quiz (003),
  answer registered (006), Settings (013/015) — visibly distinct real screens confirm actual
  cross-screen navigation occurred.
- **Bug fix** — the sandboxed XCUITest runner could not read the host file at
  `HANA_UI_SCRIPT_PATH` (a path-only run loaded zero steps). The loader
  (`HanahuacUITests/UIActionScript.swift`) now falls back to the inline `HANA_UI_SCRIPT` payload,
  and `scripts/ui-walkthrough.sh` exports both, so `just ui-walkthrough` genuinely drives the full
  script. Includes one shellcheck SC2155 fix in the helper.

## Test plan

- [x] `just lint` green (including shellcheck on the helper)
- [x] `just test` green
- [x] `just ui-walkthrough` drives the full 16-step script end-to-end
- [x] Screenshots read back and confirmed to show Home, Multiple Choice quiz, answer registered, and Settings
- [x] All supported driver actions exercised collectively across the run
