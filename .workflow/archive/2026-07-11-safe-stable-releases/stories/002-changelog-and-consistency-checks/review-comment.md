<!-- independent-review -->
## Independent review — round 1: APPROVED

Fresh cold-context 4-eye review of head `ae00827` (full diff, all conditional branches traced, checks executed empirically).

**Verdict: APPROVED** — no blocking findings.

### What was verified
- **Spec compliance (all ACs met):** `CHANGELOG.md` is Keep-a-Changelog with `[Unreleased]` and a seeded pre-release summary; the release-procedure convention is documented in the header comment; `scripts/check-changelog.sh` and `scripts/check-tag-version.sh` are standalone, fully-delivered scripts (not stubs) wired into `just check-changelog` / `just check-tag-version` / `just test-release-scripts`; no per-PR blocking CI check touched; CI (incl. shellcheck/yamllint) green.
- **Empirical runs, not just reading:** `just test-release-scripts` passes locally (36/36 assertions). Negative cases genuinely fail non-zero with stderr messages — no degradation. Extra edge probes beyond the committed tests all behaved correctly:
  - default run against the real repo (`check-changelog` with no args) derives `1.0.0` from `project.yml` and correctly fails (no released section yet) with a clear message;
  - `check-tag-version v1.0.0` against the real `project.yml` passes;
  - version `1.0.0` does NOT falsely match a `## [1.0.0-rc.1]` heading (regex is properly anchored and dot-escaped);
  - duplicated `MARKETING_VERSION` lines are rejected with the "expected exactly one" error, mirroring `bump-version.py`.
- **Branch-by-branch shell trace:** arg-parsing loops handle missing option values, unknown options, and extra positionals; `fail` inside `$(…)` correctly aborts the caller under `set -e`; `grep -c` counting and `BASH_REMATCH` extraction are sound; test harness `RC/OUT/ERR` capture is correct.
- **Conventions:** per-script helper duplication in the test scripts matches the established `test-bump-version.sh` pattern; `test-lib.sh` contract used correctly.

### Findings
1 non-blocking inline comment: `read_marketing_version()` duplicated between the two check scripts (deliberate per the standalone-scripts spec requirement; consider a sourced lib only if a third shell consumer appears).

Formal merge gate: to be posted by the separate `code-owner-review` check on this SHA.
