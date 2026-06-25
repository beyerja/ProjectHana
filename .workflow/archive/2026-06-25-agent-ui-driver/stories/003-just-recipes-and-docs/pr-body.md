## Goal

Wrap the XCUITest driver (story 001) into a reusable, end-to-end `just` capability so the main
session and future workflow sub-agents (`verify-story`, `verify-feature`) can run it without
remembering raw `xcodebuild` invocations. Authors write a JSON action script, run one recipe, and
read back the artifacts under `.workflow/ui-walkthrough/<run>/`.

## Summary of changes

- **`just ui-walkthrough script run=""` recipe** — builds the `HanahuacUITests` target and runs
  only `UIDriverTests/testRunUIScript` against the booted simulator, plumbing the action script,
  run name, and `HANA_REPO_ROOT` through, then prints the resulting artifact directory. Style
  matches the existing `justfile`: worktree-aware (`{{sim}}`, `{{sim_dd}}`, per-worktree
  DerivedData), allowlistable command shapes (no `cd &&`, no heredocs/`$(…)`, no poll loops),
  tools via direnv/flake.
- **`scripts/ui-walkthrough.sh`** — committed, shellcheck-clean helper doing the run-dir creation,
  env plumbing, and `xcodebuild` glue. It exports `TEST_RUNNER_HANA_*` so the env actually reaches
  the sandboxed XCUITest runner (`xcodebuild` strips the prefix before injecting), closing a wiring
  gap story 001 deferred. No driver source changed.
- **Canonical layout under `.workflow/ui-walkthrough/`** — action scripts at `scripts/<name>.json`
  (committed example `smoke.json`); run artifacts at `<run>/`.
- **`.workflow/ui-walkthrough/README.md`** — documents the action-script JSON schema, supported
  actions, the env-var contract, artifact locations, the write → run → read loop, and the
  "compiled test cycle ~tens of seconds, not live frame-by-frame" performance reality.
- **Tree hygiene** — removed root debris (`verify-script.json`, `verify001.xctestplan`) and stray
  story-001 verify run dirs; `.gitignore` now ignores ui-walkthrough run-output dirs while keeping
  `scripts/` + `README.md` tracked.

## Wiring proof

`just ui-walkthrough` against iPhone 17 / iOS 26.5 → **TEST SUCCEEDED**, producing `000-step.png`
+ `000-step.json` (run output intentionally NOT committed).

## Test plan

- [x] `just ui-walkthrough` builds `HanahuacUITests` + runs `UIDriverTests/testRunUIScript` and
      prints the artifact dir (AC 1)
- [x] Recipe is worktree-aware with allowlistable shapes (AC 2)
- [x] `scripts/ui-walkthrough.sh` is shellcheck-clean / passes `just lint-sh` (AC 3)
- [x] README documents schema, actions, artifact locations, write→run→read loop, perf reality
      (AC 4)
- [x] Trivial script (launch + dump) succeeds and produces a screenshot + element dump (AC 5)
- [x] `just lint` green (swift/py/sh/nix/yaml/l10n) (AC 6)

## Notes

Not wired into blocking PR CI (out of scope per the feature). Depends on story 001 (driver/target)
and benefits from story 002 accessibility identifiers for cleaner example scripts.
