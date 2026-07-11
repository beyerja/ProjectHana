# Tasks — 002 CHANGELOG + version/changelog consistency checks

Conventions to follow (from story 001, inspected in this worktree):
- `project.yml` is the single source of truth; the version lives on a quoted line
  `MARKETING_VERSION: "X.Y.Z"` (line ~243). Mirror `scripts/bump-version.py` semantics when
  reading it: require exactly ONE match, clear stderr message + non-zero exit otherwise.
- Script tests source `scripts/test-lib.sh` (TMPROOT + trap, `ok`/`ko`, final
  `Result: N passed, M failed.` + `[[ ${fail} -eq 0 ]]`) and build fixtures with `printf`
  into `${TMPROOT}` (never heredocs) — see `scripts/test-bump-version.sh` as the template.
- Script tests are wired as their own just recipe (like `test-version-scripts`), NOT into the
  xcodebuild `just test` recipe and NOT into any per-PR blocking workflow
  (`ci.yml` / `lint.yml` / `secret-scan.yml` must stay byte-identical).
- Scripts accept `--file`-style path overrides so tests run against throwaway fixtures with
  zero repo mutation and no direnv/xcodegen dependency.

## Tasks
- [x] 001: Seed root `CHANGELOG.md` in Keep-a-Changelog format. HTML comment header (2–4 lines)
      documenting the release-procedure convention: `[Unreleased]` content moves under the new
      `## [X.Y.Z] - YYYY-MM-DD` heading as part of the version-bump PR (full runbook lands in
      story 005). Standard Keep-a-Changelog preamble, then an `## [Unreleased]` section seeded
      with a brief summary of the current pre-release state (app at MARKETING_VERSION 1.0.0,
      no tagged releases yet; versioning/bump tooling from story 001). Markdown only — no new
      YAML/shell/python, so no lint surface; do not touch any workflow file.
- [x] 002: Add `scripts/check-changelog.sh` (bash, executable, shellcheck-clean).
      Behavior: verify `CHANGELOG.md` contains a version section heading `## [X.Y.Z]` for the
      version under check. Version comes from `$1` if given, otherwise derived from
      `MARKETING_VERSION` in `project.yml`. Support `--changelog <path>` and
      `--project-yml <path>` overrides (defaults: repo-root files, resolved from the script's
      own dir like `test-bump-version.sh` does). Failure modes, each with a clear one-line
      stderr message + exit non-zero: missing changelog file, no section for the version,
      non-semver version argument, missing/duplicated `MARKETING_VERSION` line. Success prints
      a short confirmation and exits 0. `[Unreleased]` never satisfies the check.
- [x] 003: Add `scripts/check-tag-version.sh` (bash, executable, shellcheck-clean).
      Behavior: given a tag as `$1` (required), fail unless it is `v` + strict semver with an
      optional semver prerelease suffix (`vX.Y.Z` or `vX.Y.Z-<prerelease>` e.g. `v1.1.0-rc.1`)
      AND its `X.Y.Z` base equals `MARKETING_VERSION` from `project.yml`. Support
      `--project-yml <path>` override for tests. Failure modes with clear stderr + non-zero
      exit: missing tag arg, missing `v` prefix, non-semver base, malformed prerelease suffix,
      base != MARKETING_VERSION, missing/duplicated `MARKETING_VERSION` line. Success prints
      the matched tag/version and exits 0.
- [x] 004: Add `scripts/test-check-changelog.sh` following the `test-bump-version.sh` pattern
      (source `test-lib.sh`, printf-built fixtures in TMPROOT). Positive cases: explicit
      version present in fixture changelog -> exit 0; version derived from a fixture
      project.yml -> exit 0; real repo `CHANGELOG.md` + real `project.yml` -> asserts the
      seeded state (1.0.0 has no released section yet, so assert the DERIVED check currently
      fails non-zero — proving the negative path against real files — or skip real-file
      coupling and keep it fixture-only; prefer fixture-only if this creates ordering coupling
      with the version-bump flow). Negative cases: version absent -> non-zero + stderr;
      `[Unreleased]`-only changelog -> non-zero; missing changelog file -> non-zero; bogus
      version arg -> non-zero; fixture project.yml without MARKETING_VERSION -> non-zero.
- [x] 005: Add `scripts/test-check-tag-version.sh`, same harness pattern. Positive cases:
      `v1.0.0` vs fixture MARKETING_VERSION 1.0.0 -> 0; prerelease `v1.1.0-rc.1` vs 1.1.0 -> 0.
      Negative cases: version mismatch (`v1.0.1` vs 1.0.0) -> non-zero + stderr; missing `v`
      prefix (`1.0.0`) -> non-zero; two-component tag (`v1.0`) -> non-zero; malformed
      prerelease (`v1.0.0-`) -> non-zero; missing tag argument -> non-zero; fixture without
      MARKETING_VERSION line -> non-zero.
- [x] 006: Wire just recipes in `justfile`: (a) `test-release-scripts` running both new test
      scripts (mirror the `test-bot-scripts` recipe shape: bash shebang block, `set -euo
      pipefail`, run each test script); (b) thin pass-through recipes `check-changelog
      *args` and `check-tag-version tag` invoking the scripts, so story 003's `release-check`
      can compose them. Comments on each recipe per house style. No changes to `test`, `lint`,
      or any workflow file.
- [x] 007: Full verification pass: run `just lint` (shellcheck/ruff/yamllint gates stay
      green), `just test-release-scripts` (all pass), plus one manual positive AND one manual
      negative invocation of each check script recorded in the story log: positive —
      `just check-tag-version v1.0.0` (and `v1.0.0-rc.1`, base matches 1.0.0) exits 0;
      negative — `just check-tag-version v9.9.9` exits non-zero. For the changelog check the
      repo state itself gives the negative case (`just check-changelog` in derived mode fails
      until a `[1.0.0]` section exists — expected pre-release; document it in the log) and a
      fixture with a `[1.0.0]` section gives the positive case. Confirm `git diff --stat`
      touches no `.github/workflows/*` file.
