# Tasks — 001 Versioning scheme + bump tooling

Context for all tasks (verified against the worktree):
- Version values exist in exactly TWO files today: `project.yml` (source of truth:
  `MARKETING_VERSION: "1.0"`, `CURRENT_PROJECT_VERSION: "1"`, lines ~243-244) and the committed,
  regenerated `Hanahuac.xcodeproj/project.pbxproj`. Nothing else references them — keep it that way.
- `just generate` = `direnv exec . xcodegen generate` (justfile line ~27). The pbxproj IS committed,
  so a correct `just bump patch` diff touches `project.yml` + `Hanahuac.xcodeproj/project.pbxproj`
  and nothing else.
- Lint gates that must stay green: `just lint` → ruff check + ruff format --check (new .py),
  shellcheck (new .sh), yamllint (justfile edits are not YAML, but project.yml is).
- Allowlistable shapes only: no `cd &&` (use `git -C`, `just -f <dir>/justfile`), no heredocs,
  no `$(…)` payloads, no poll loops — both in the script itself and in how you run things.
- Test-harness precedent: `scripts/test-lib.sh` sourced by `scripts/test-gh-review-bot.sh` /
  `scripts/test-secret-scan-hook.sh`, wired into `just test-bot-scripts`. Follow that pattern.

## Tasks
- [x] 001: Normalize `MARKETING_VERSION` in `project.yml` from `"1.0"` to `"1.0.0"` (three-component
      semver, feature Assumption 2) and run `just generate` so the committed
      `Hanahuac.xcodeproj/project.pbxproj` picks up the normalized value. Verify the diff touches
      only those two files. Commit as its own change so the bump-script diff stays reviewable.
- [x] 002: Add `scripts/bump-version.py` (stdlib-only Python, ruff-clean including
      `ruff format`). Behavior:
      - CLI: one required positional arg `major|minor|patch`; optional `--file <path>` (default
        `project.yml`) so tests can run against a temp copy; optional `--no-generate` to skip
        project regeneration in tests.
      - Edit `project.yml` with targeted regex line replacement of the
        `MARKETING_VERSION: "X.Y.Z"` and `CURRENT_PROJECT_VERSION: "N"` lines — do NOT round-trip
        through a YAML library (the file's extensive comments and formatting must be preserved
        byte-for-byte elsewhere).
      - Validation (clear message to stderr + non-zero exit): reject an invalid part argument;
        reject a current `MARKETING_VERSION` that is not strict `X.Y.Z` (all numeric, exactly three
        components — e.g. the pre-normalization `1.0` must be rejected, pointing at task 001);
        reject a `CURRENT_PROJECT_VERSION` that is not a positive integer; fail if either key is
        missing or matched more than once.
      - Bump semantics: `major` → X+1.0.0, `minor` → X.Y+1.0, `patch` → X.Y.Z+1; build number
        always +1. Print old → new values for both fields on success.
      - Regeneration: unless `--no-generate`, invoke xcodegen the same way `just generate` does
        (`direnv exec . xcodegen generate`) via subprocess with an argument list (no shell=True),
        and propagate a non-zero exit.
      - Header comment (docstring) stating the convention: releases are annotated
        `v<MAJOR>.<MINOR>.<PATCH>` tags on `main` only; `project.yml` is the single source of truth
        for `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`; manual edits to these fields are
        discouraged — use `just bump <part>` (full runbook lands in story 005).
- [x] 003: Add a `bump part` recipe to the `justfile` that runs
      `python3 scripts/bump-version.py {{part}}` (script does the regeneration itself, so the
      recipe stays a single line and works from any worktree via `just -f <dir>/justfile bump patch`).
      Include a one-line doc comment above the recipe naming the tag convention and pointing at
      the script header, consistent with the other recipe comments in the file.
- [x] 004: Add `scripts/test-bump-version.sh` (shellcheck-clean, sources `scripts/test-lib.sh`,
      mirrors `scripts/test-gh-review-bot.sh` structure) exercising the script against a temp copy
      via `--file <tmp>/project.yml --no-generate`:
      - happy paths: patch `1.0.0`→`1.0.1`, minor `1.0.1`→`1.1.0` (patch resets), major →`2.0.0`
        (minor+patch reset); build number +1 each time; rest of the file byte-identical.
      - error paths (non-zero exit, message on stderr): invalid part arg (`bogus`, missing arg),
        non-semver current value (`1.0`), non-integer build number, missing key.
      Wire it into the `test-bot-scripts` recipe or a sibling `test-version-scripts` recipe —
      whichever keeps the justfile consistent; no CI workflow changes (per-PR blocking checks are
      frozen).
- [x] 005: End-to-end validation in the worktree: run
      `just -f <worktree>/justfile bump patch`, confirm with `git -C <worktree> status --short`
      that the diff touches ONLY `project.yml` and `Hanahuac.xcodeproj/project.pbxproj` and that
      both files carry the same new version/build values; then revert the scratch bump
      (`git -C <worktree> checkout -- project.yml Hanahuac.xcodeproj/project.pbxproj`) so the
      committed state stays at the story's baseline version. Run `just -f <worktree>/justfile lint`
      and the new test script; all green.
