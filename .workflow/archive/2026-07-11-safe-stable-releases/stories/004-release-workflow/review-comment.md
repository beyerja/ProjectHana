<!-- independent-review -->
## Independent review — round 1

**Verdict: APPROVED** — no blocking findings; 2 non-blocking nits posted inline.

### What was verified (fresh cold-context review of head `546b11e`)

- **Spec compliance:** `release.yml` triggers on `v*` tag push + `workflow_dispatch` with `dry_run` (default true), no `pull_request` trigger. All seven gates present in the spec'd order, each reusing existing `just` recipes / story-002 scripts rather than re-implementing in YAML: (a) `check-tag-version.sh` (correctly skipped in dry-run with an explanatory step), (b) `check-changelog.sh`, (c) `just lint`, (d) xcodegen + full Catalyst `xcodebuild test` mirroring ci.yml verbatim, (e) `just geo-packs-check`, (f) `just verify-odr-packs`, (g) `just verify-base-only-release`. Unsigned `.xcarchive` (ditto `--norsrc` zip) + `.ipa` via the story-003 `just archive` recipe + `SHA256SUMS.txt`, uploaded with `if-no-files-found: error`. Separate publish job creates the Release via `gh release create --verify-tag --notes-file --generate-notes`, `--prerelease` for hyphenated tags. App Store placeholders gated on `vars.APPSTORE_UPLOAD_ENABLED` + a step-level secret-presence detection step, with an explanatory skip step whose condition is the exact complement.
- **Conditional-branch trace:** gate (a) run/skip `if:` expressions are exact complements; `inputs.dry_run` evaluates false on tag-push events; every path into the publish job has passed gate (a)'s strict tag-format validation, so `contains(ref_name, '-')` prerelease detection is safe; publish is correctly reachable via `workflow_dispatch` with `dry_run=false` on a tag ref.
- **Workflow security:** top-level `permissions: contents: read`; the publish job holds the workflow's sole `contents: write`. All `github.ref_name` uses flow through `env:` — nothing untrusted is interpolated into `run:` bodies. No `pull_request` trigger → no untrusted-context exposure; artifacts flow only within a single run; secret-presence detection via step `env:` is the correct pattern (`secrets` genuinely unavailable in step `if:`).
- **Blocking-CI constraint:** `git diff origin/main...HEAD -- ci.yml lint.yml secret-scan.yml` is 0 bytes.
- **Empirical checks (run locally):** `just test-release-scripts` green — all 22 new `extract-changelog-section.sh` assertions pass. Action majors verified live against GitHub: `actions/checkout` v7.0.0, `cachix/install-nix-action` v31.10.7, `actions/upload-artifact` v7.0.1, `actions/download-artifact` v8.0.1 — the PR-body table is accurate. `gh release create --help` shows no `--notes-file`/`--generate-notes` exclusivity. Flake default dev shell contains `just` + `direnv`; `check-tag-version.sh` accepts semver prerelease suffixes; `_sfx` is empty when `HANA_FEATURE_SLUG` is unset, so the `/tmp/Hanahuac-archive` paths in the workflow are correct on runners.

### Non-blocking findings (inline)

1. `.github/workflows/release.yml` gate (b): an empty-body CHANGELOG section passes `check-changelog.sh` (heading-presence only) but fails `extract-changelog-section.sh` in the publish job — the failure surfaces only after the full ~90-min gates job, and dry-runs never exercise the extractor. Suggest front-loading the empty-body rule into gate (b).
2. `scripts/extract-changelog-section.sh`: third verbatim copy of `read_marketing_version` + option-parsing scaffold across the release scripts; a sourced `release-lib.sh` would prevent drift. Fine as a follow-up.

Note: the release pipeline itself is necessarily unproven on a fresh runner until the story-005 `workflow_dispatch` dry-run — that post-merge validation is already planned in the feature's story 005.
