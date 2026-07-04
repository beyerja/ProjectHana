set shell := ["bash", "-c"]

# Ensure tools and Xcode are always available regardless of calling shell's PATH
export DEVELOPER_DIR := "/Applications/Xcode.app/Contents/Developer"
export PATH := env_var("HOME") + "/.nix-profile/bin:" + env_var("PATH")

# --- Per-worktree build isolation -------------------------------------------------
# `wt` is the worktree/feature-slug id. Parallel feature workflows (each in its own git
# worktree) override it so their DerivedData, /tmp build output, and simulator destination
# never collide. It defaults from the orchestrator's HANA_FEATURE_SLUG env var, falling back
# to empty — and an empty `wt` reproduces the original single-checkout paths byte-for-byte.
# Override per invocation with `just wt=my-feature test`, or rely on the exported env var.
wt := env_var_or_default("HANA_FEATURE_SLUG", "")

# Path suffix: "-<wt>" when isolated, "" otherwise (keeps legacy /tmp paths in a plain checkout).
_sfx := if wt == "" { "" } else { "-" + wt }

# Per-worktree DerivedData + /tmp build output dirs (suffixed only when `wt` is set).
mac_dd := "/tmp/Hanahuac-mac-build" + _sfx
sim_dd := "/tmp/Hanahuac-sim-build" + _sfx

# Simulator destination name. Defaults to the shared "iPhone 17"; set HANA_SIM_NAME (or `just
# sim="iPhone 17 (feat)" …`) to a per-worktree clone's name to avoid simulator contention.
sim := env_var_or_default("HANA_SIM_NAME", "iPhone 17")

# Regenerate Hanahuac.xcodeproj from project.yml (xcodegen comes from the flake dev shell via direnv)
generate:
    direnv exec . xcodegen generate

# Render the 1024x1024 app icon PNG from the SwiftUI brand mark
icon:
    xcrun swift scripts/make-icon.swift

# Bump the app version (part = major|minor|patch): updates MARKETING_VERSION +
# CURRENT_PROJECT_VERSION in project.yml (single source of truth) and regenerates the Xcode
# project. Releases are annotated v<MAJOR>.<MINOR>.<PATCH> tags on main only — full convention
# in the scripts/bump-version.py header.
bump part:
    python3 scripts/bump-version.py {{part}}

# Regenerate the per-language geo-name ODR pack JSON (fr/de/ko/nah) from the bundled geo data.
geo-packs:
    python3 scripts/generate-geo-packs.py

# Verify the committed geo packs are up to date with the bundled geo source data.
geo-packs-check:
    python3 scripts/generate-geo-packs.py --check

# Verify the ODR-tagged packs are DATA-ONLY (no executable/Mach-O content) and that no custom
# network/crypto/signature/hash-verification trust code was introduced. Basis for the async CI job.
verify-odr-packs:
    bash scripts/verify-odr-packs.sh

# Validate the zero-packs offline base-only launch path against the locally built Mac Catalyst app:
# base languages (en/es-MX) present, non-base languages declared on-demand. Depends on build-mac.
verify-base-only: build-mac
    bash scripts/verify-base-only-bundle.sh '{{mac_dd}}'

# Run the full test suite on the simulator (per-worktree DerivedData + destination when `wt` is set)
test:
    xcodebuild test \
        -project Hanahuac.xcodeproj \
        -scheme Hanahuac \
        -destination 'platform=iOS Simulator,name={{sim}}' \
        -derivedDataPath '{{sim_dd}}' \
        2>&1 | grep -E "TEST SUCCEEDED|TEST FAILED|error:|Test Case.*failed" \
             | grep -v "CoreData|simctl|appintents"

# Build the Mac Catalyst app (ad-hoc signed)
build-mac:
    xcodebuild build \
        -project Hanahuac.xcodeproj \
        -scheme Hanahuac \
        -destination 'platform=macOS,variant=Mac Catalyst' \
        -derivedDataPath '{{mac_dd}}' \
        CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
        2>&1 | tail -3

# Build, install to /Applications, and launch (atomic).
# Snapshots the user's progress (SwiftData store + preferences) to a timestamped backup BEFORE
# replacing the app bundle, and verifies the live store survived afterwards — so a local upgrade can
# never be the cause of progress loss. Backups live under
# ~/Library/Application Support/Hanahuac-backups/ (last 10 kept). See scripts/backup-progress.sh.
install: build-mac
    #!/usr/bin/env bash
    set -euo pipefail
    APP=$(find '{{mac_dd}}' -name "Hanahuac.app" -maxdepth 6 | head -1)
    echo "==> Backing up local progress before install…"
    bash scripts/backup-progress.sh backup
    pkill -x Hanahuac 2>/dev/null || true
    sleep 1
    rm -rf /Applications/Hanahuac.app
    cp -R "$APP" /Applications/
    open /Applications/Hanahuac.app
    echo "==> Verifying progress survived install…"
    bash scripts/backup-progress.sh verify

# List open PRs
pr-list:
    gh pr list --repo beyerja/ProjectHana

# Show CI run status for a branch
ci branch:
    gh run list --repo beyerja/ProjectHana --branch {{branch}}

# Run every linter (fail-on-violation). Mirrors the CI lint job; all tools come from the
# flake dev shell via direnv (no hardcoded /nix paths).
lint: lint-swift lint-py lint-sh lint-nix lint-yaml l10n-check
    @echo "lint: all linters passed."

# Static localization-completeness gate. Data-driven: the locales checked are discovered from the
# Hanahuac/<code>.lproj dirs on disk, and each is assigned an enforcement role in the script's
# ROLE_MAP. Every on-disk .lproj MUST have a declared role or the check FAILS (a new .lproj can never
# be silently skipped). BASE (en, es-MX) and FULL (de, fr, es-ES, it, pl, nl, sr, ko — plus the
# pre-declared future locales ja, zh-Hans, hi, ar, bn, pt-BR, ur once their .lproj lands) must
# contain the full canonical key set; PARTIAL fallback-permitted locales (nah, yua, ca, eu) may be a
# subset (gaps resolve via each locale's fallback chain). Stdlib-only python; exits non-zero on any
# missing required key or an unclassified on-disk locale. Folded into `just lint` so CI enforces it.
l10n-check:
    python3 scripts/check-l10n-completeness.py

# Lint Swift sources: SwiftLint rules (strict) + swiftformat --lint (formatting gate).
lint-swift:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== SwiftLint =="
    direnv exec . swiftlint lint --strict --config .swiftlint.yml
    echo "== swiftformat --lint =="
    direnv exec . swiftformat --lint .
    echo "swift: clean."

# Lint Python helper scripts with Ruff (check + format --check).
lint-py:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== ruff check =="
    direnv exec . ruff check .
    echo "== ruff format --check =="
    direnv exec . ruff format --check .
    echo "python: clean."

# Lint the repo's tracked shell scripts with shellcheck (from the flake dev shell via direnv)
lint-sh:
    #!/usr/bin/env bash
    set -euo pipefail
    scripts=()
    while IFS= read -r f; do
        scripts+=("$f")
    done < <(git ls-files '*.sh')
    if [[ ${#scripts[@]} -eq 0 ]]; then
        echo "No tracked .sh files to lint."
        exit 0
    fi
    printf 'Linting %d shell script(s):\n' "${#scripts[@]}"
    printf '  %s\n' "${scripts[@]}"
    # shellcheck comes from the flake dev shell via direnv (no hardcoded /nix path)
    direnv exec . shellcheck "${scripts[@]}"
    echo "shellcheck: all scripts passed."

# Check Nix files are formatted (nixfmt-rfc-style, --check = fail-on-violation).
lint-nix:
    #!/usr/bin/env bash
    set -euo pipefail
    nixfiles=()
    while IFS= read -r f; do nixfiles+=("$f"); done < <(git ls-files '*.nix')
    if [[ ${#nixfiles[@]} -eq 0 ]]; then echo "No tracked .nix files."; exit 0; fi
    direnv exec . nixfmt --check "${nixfiles[@]}"
    echo "nix: formatted."

# Lint tracked YAML files (yamllint). Config-defined errors fail the gate; line-length is a
# non-blocking warning, so we deliberately do NOT pass --strict (which would fail on warnings).
lint-yaml:
    #!/usr/bin/env bash
    set -euo pipefail
    yamlfiles=()
    while IFS= read -r f; do yamlfiles+=("$f"); done < <(git ls-files '*.yml' '*.yaml')
    if [[ ${#yamlfiles[@]} -eq 0 ]]; then echo "No tracked YAML files."; exit 0; fi
    direnv exec . yamllint "${yamlfiles[@]}"
    echo "yaml: clean."

# Activate the committed git hooks by setting core.hooksPath=.githooks (secret-scan + main guard).
# Run once per clone. Idempotent.
install-hooks:
    bash scripts/install-hooks.sh

# Run the token-free bot-script tests (wrapper + secret-scan hook). No real token required.
test-bot-scripts:
    #!/usr/bin/env bash
    set -euo pipefail
    bash scripts/test-gh-review-bot.sh
    bash scripts/test-secret-scan-hook.sh

# Run the version-tooling tests (bump-version.py against temp fixture copies; no xcodegen run).
test-version-scripts:
    bash scripts/test-bump-version.sh

# Delegate to agent telemetry logger
log *args:
    bash scripts/agent-log.sh {{args}}

# Parse .workflow/telemetry/agents-*.jsonl and print a summary table (agent, runs, avg duration, avg est tokens, retries)
telemetry:
    python3 scripts/telemetry-summary.py

# Same summary but over live + committed archived telemetry — the cross-run view evaluate-workflow Phase 2b needs
telemetry-history:
    python3 scripts/telemetry-summary.py --history

# Build the app for the iOS Simulator; prints the .app bundle path on success
# (per-worktree DerivedData + destination when `wt`/HANA_SIM_NAME are set)
build-sim:
    #!/usr/bin/env bash
    set -euo pipefail
    xcodebuild build \
        -project Hanahuac.xcodeproj \
        -scheme Hanahuac \
        -destination 'platform=iOS Simulator,name={{sim}}' \
        -derivedDataPath '{{sim_dd}}' \
        2>&1 | tail -5
    APP=$(find '{{sim_dd}}' -name "Hanahuac.app" -maxdepth 10 | head -1)
    echo "Built: $APP"

# Install the app to the booted simulator (depends on build-sim)
install-sim: build-sim
    #!/usr/bin/env bash
    set -euo pipefail
    APP=$(find '{{sim_dd}}' -name "Hanahuac.app" -maxdepth 10 | head -1)
    xcrun simctl install booted "$APP"
    echo "Installed: $APP"

# Boot the simulator named by `sim` (default iPhone 17; no-op if already booted)
boot-sim:
    xcrun simctl boot "{{sim}}" 2>/dev/null || true

# Launch the installed app on the booted simulator
launch-sim:
    xcrun simctl launch booted com.hanahuac.app

# Take a screenshot of the booted simulator and save it to the given path; exits non-zero on failure
screenshot-sim path:
    #!/usr/bin/env bash
    set -euo pipefail
    xcrun simctl io booted screenshot "{{path}}"
    if [[ ! -s "{{path}}" ]]; then
        echo "ERROR: screenshot file missing or empty at {{path}}" >&2
        exit 1
    fi
    echo "Screenshot saved to {{path}}"

# Drive the app with the data-driven XCUITest UI driver and collect per-step screenshot + element-dump
# artifacts under `.workflow/ui-walkthrough/<run>/`. Builds + runs ONLY
# HanahuacUITests/UIDriverTests/testRunUIScript against the booted `{{sim}}` (per-worktree DerivedData).
#
#   `script` — action-script JSON path (repo-relative or absolute);
#              defaults to the committed `.workflow/ui-walkthrough/scripts/smoke.json`.
#   `run`    — run directory name; defaults to "" so the recorder picks a UTC timestamp.
#
# Each run is a compiled `xcodebuild test` cycle (~tens of seconds), NOT a live frame-by-frame session:
# write a script, run once, then read the emitted `NNN-step.png` + `NNN-step.json` pairs. The
# JSON schema + supported actions are documented in `.workflow/ui-walkthrough/README.md`. The glue
# (run-dir resolution, env-var plumbing, artifact-dir echo) lives in `scripts/ui-walkthrough.sh`.
ui-walkthrough script=".workflow/ui-walkthrough/scripts/smoke.json" run="":
    bash scripts/ui-walkthrough.sh '{{script}}' '{{run}}' '{{sim}}' '{{sim_dd}}'

# Same as `ui-walkthrough`, but forces a right-to-left layout (sets HANA_FORCE_RTL) so the captured
# artifacts show the mirrored RTL layout. Drives the greenfield RTL infrastructure (story 008) without
# requiring ar/ur content; stories 009/010 use this to verify Arabic/Urdu render correctly mirrored.
ui-walkthrough-rtl script=".workflow/ui-walkthrough/scripts/smoke.json" run="":
    HANA_FORCE_RTL=1 bash scripts/ui-walkthrough.sh '{{script}}' '{{run}}' '{{sim}}' '{{sim_dd}}'
