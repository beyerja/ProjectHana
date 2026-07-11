<!-- independent-review -->
## Independent review — round 1

**Verdict: APPROVED**

Fresh cold-context review of head `3c8f6e1` (deep pass at high effort, all finder angles run inline against the full diff plus cross-file traces).

### Acceptance criteria — all satisfied
- **Empirical proof first**: unsigned Release device archive (`generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO`) PROVEN and recorded in the story log with the exact command before tooling was finalized; no Catalyst fallback needed.
- **`just archive`**: uses the proven command, per-worktree isolation (`archive_dd`/`archive_out` via `_sfx`), emits `.xcarchive` and `.ipa` paths.
- **`.ipa` feasibility**: answered — feasible; `scripts/package-ipa.sh` produces a clean unsigned `Payload/Hanahuac.app` zip (`ditto --norsrc`).
- **`just release-check [tag]`**: all six spec'd steps present (lint, Catalyst test suite, geo-packs-check, verify-odr-packs, Release build + base-only bundle verify, story-002 changelog/tag checks); ran end-to-end green both with and without a tag per the log. The `wt` propagation into nested `just` invocations is handled explicitly.
- **No signing/credentials**: `CODE_SIGNING_ALLOWED=NO` throughout; the ipa is a plain zip.
- **Constraints**: `git diff origin/main...HEAD -- .github/` is empty — `ci.yml`/`lint.yml`/`secret-scan.yml` untouched. Shellcheck covers the new script via `lint-sh` (CI green).

### Verified cross-file traces
- `verify-base-only-release` hands a **Release** DerivedData path to `verify-base-only-bundle.sh` — safe: the script locates `Hanahuac.app` config-agnostically via `find`.
- `check-changelog` (release-check step 6, no arg) derives 1.0.0 from project.yml and requires the `## [1.0.0]` section — the CHANGELOG move is necessary, not cosmetic.
- `test-mac` skips **execution** (not compilation) of `HanahuacUITests` locally — documented empirical deviation (runner hangs without UI-automation permissions), consistent with the repo's Catalyst-UITests-run-in-CI convention; CI's required check still executes them. Non-blocking.

### Findings (2, both non-blocking, posted inline)
1. `justfile` `test-mac`: the `grep -v "CoreData|simctl|appintents"` noise filter is a no-op (BRE treats `|` literally); needs `-E`. Cosmetic — copied from the existing `test` recipe, and the new recipe otherwise improves on it with `set -euo pipefail`.
2. `CHANGELOG.md`: `## [1.0.0] - 2026-07-05` predates the actual tag; date may need refreshing at tag time (note for stories 004/005).

No correctness bugs, no unmet acceptance criteria, no constraint violations.

**STATUS: APPROVED**
