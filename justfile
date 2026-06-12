set shell := ["bash", "-c"]

# Ensure tools and Xcode are always available regardless of calling shell's PATH
export DEVELOPER_DIR := "/Applications/Xcode.app/Contents/Developer"
export PATH := env_var("HOME") + "/.nix-profile/bin:" + env_var("PATH")

# Run the full test suite on the iPhone 17 simulator
test:
    xcodebuild test \
        -project ProjectHana.xcodeproj \
        -scheme ProjectHana \
        -destination 'platform=iOS Simulator,name=iPhone 17' \
        2>&1 | grep -E "TEST SUCCEEDED|TEST FAILED|error:|Test Case.*failed" \
             | grep -v "CoreData|simctl|appintents"

# Build the Mac Catalyst app (ad-hoc signed)
build-mac:
    xcodebuild build \
        -project ProjectHana.xcodeproj \
        -scheme ProjectHana \
        -destination 'platform=macOS,variant=Mac Catalyst' \
        -derivedDataPath /tmp/ProjectHana-mac-build \
        CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
        2>&1 | tail -3

# Build, install to /Applications, and launch (atomic)
install: build-mac
    #!/usr/bin/env bash
    set -euo pipefail
    APP=$(find /tmp/ProjectHana-mac-build -name "ProjectHana.app" -maxdepth 6 | head -1)
    pkill -x ProjectHana 2>/dev/null || true
    sleep 1
    rm -rf /Applications/ProjectHana.app
    cp -R "$APP" /Applications/
    open /Applications/ProjectHana.app

# List open PRs
pr-list:
    gh pr list --repo beyerja/ProjectHana

# Show CI run status for a branch
ci branch:
    gh run list --repo beyerja/ProjectHana --branch {{branch}}

# Delegate to agent telemetry logger
log *args:
    bash scripts/agent-log.sh {{args}}
