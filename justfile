set shell := ["bash", "-c"]

# Ensure tools and Xcode are always available regardless of calling shell's PATH
export DEVELOPER_DIR := "/Applications/Xcode.app/Contents/Developer"
export PATH := env_var("HOME") + "/.nix-profile/bin:" + env_var("PATH")

# Run the full test suite on the iPhone 17 simulator
test:
    xcodebuild test \
        -project Hanahuac.xcodeproj \
        -scheme Hanahuac \
        -destination 'platform=iOS Simulator,name=iPhone 17' \
        2>&1 | grep -E "TEST SUCCEEDED|TEST FAILED|error:|Test Case.*failed" \
             | grep -v "CoreData|simctl|appintents"

# Build the Mac Catalyst app (ad-hoc signed)
build-mac:
    xcodebuild build \
        -project Hanahuac.xcodeproj \
        -scheme Hanahuac \
        -destination 'platform=macOS,variant=Mac Catalyst' \
        -derivedDataPath /tmp/Hanahuac-mac-build \
        CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
        2>&1 | tail -3

# Build, install to /Applications, and launch (atomic)
install: build-mac
    #!/usr/bin/env bash
    set -euo pipefail
    APP=$(find /tmp/Hanahuac-mac-build -name "Hanahuac.app" -maxdepth 6 | head -1)
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

# Delegate to agent telemetry logger
log *args:
    bash scripts/agent-log.sh {{args}}

# Parse .workflow/telemetry/agents-*.jsonl and print a summary table (agent, runs, avg duration, avg est tokens, retries)
telemetry:
    python3 scripts/telemetry-summary.py

# Build the app for the iOS Simulator (iPhone 17); prints the .app bundle path on success
build-sim:
    #!/usr/bin/env bash
    set -euo pipefail
    xcodebuild build \
        -project Hanahuac.xcodeproj \
        -scheme Hanahuac \
        -destination 'platform=iOS Simulator,name=iPhone 17' \
        -derivedDataPath /tmp/Hanahuac-sim-build \
        2>&1 | tail -5
    APP=$(find /tmp/Hanahuac-sim-build -name "Hanahuac.app" -maxdepth 10 | head -1)
    echo "Built: $APP"

# Install the app to the booted simulator (depends on build-sim)
install-sim: build-sim
    #!/usr/bin/env bash
    set -euo pipefail
    APP=$(find /tmp/Hanahuac-sim-build -name "Hanahuac.app" -maxdepth 10 | head -1)
    xcrun simctl install booted "$APP"
    echo "Installed: $APP"

# Boot the iPhone 17 simulator (no-op if already booted)
boot-sim:
    xcrun simctl boot "iPhone 17" 2>/dev/null || true

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
