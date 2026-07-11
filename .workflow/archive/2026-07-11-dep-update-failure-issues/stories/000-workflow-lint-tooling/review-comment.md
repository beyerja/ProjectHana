<!-- independent-review -->
## Independent review — round 1: APPROVED

Deep `/code-review` pass (medium effort) over the diff at head SHA `3c45cac`. No blocking findings; no inline comments were necessary.

**What was verified:**
- **Flake wiring traced end-to-end:** the `linters` list feeds both the default dev shell (so `direnv exec .` resolves the tools locally) and the `.#lint` CI shell — `actionlint` and `check-jsonschema` are reachable on both paths, confirmed at runtime (CI Lint job green on this SHA; `just lint-gha` passes locally in the worktree, including `check-jsonschema --builtin-schema vendor.dependabot` → "ok -- validation done").
- **SC2016 fixes are behavior-preserving and safer:** the `bash -c '…'` blocks became `mapfile` + quoted `"${files[@]}"` expansion (the old unquoted `shellcheck $files` word-split). Dropping the inner `set -euo pipefail` is harmless under GHA's default `bash -e {0}`: the step bodies contain no pipes and no unset-variable reads.
- **Conditional branches in `lint-gha`:** the empty-workflows arm correctly falls through to the dependabot schema check instead of exiting early; `set -euo pipefail` + fail-on-violation tools satisfy "fails on violation".
- **All 5 acceptance criteria met:** tools in the flake lint shell; `just lint-gha` exists and works; folded into `just lint`; matching steps in the blocking `lint.yml` job using the flake shell with no new third-party actions; baseline clean (CI fully green).

**Verdict:** APPROVED — ready for the code-owner-review gate step.
