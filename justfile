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

# Build, install to /Applications, and launch (atomic)
install: build-mac
    #!/usr/bin/env bash
    set -euo pipefail
    APP=$(find '{{mac_dd}}' -name "Hanahuac.app" -maxdepth 6 | head -1)
    pkill -x Hanahuac 2>/dev/null || true
    sleep 1
    rm -rf /Applications/Hanahuac.app
    cp -R "$APP" /Applications/
    open /Applications/Hanahuac.app

# List open PRs
pr-list:
    gh pr list --repo beyerja/ProjectHana

# Show CI run status for a branch
ci branch:
    gh run list --repo beyerja/ProjectHana --branch {{branch}}

# Run every linter (fail-on-violation). Mirrors the CI lint job; all tools come from the
# flake dev shell via direnv (no hardcoded /nix paths).
lint: lint-swift lint-py lint-sh lint-nix lint-yaml
    @echo "lint: all linters passed."

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
