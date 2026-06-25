#!/usr/bin/env bash
# Drive the Hanahuac XCUITest UI driver (HanahuacUITests/UIDriverTests/testRunUIScript) against the
# booted simulator with a given action script, collecting per-step artifacts under
# `.workflow/ui-walkthrough/<run>/`. This is the glue behind `just ui-walkthrough` — it resolves the
# repo root + run name, plumbs the driver's env-var contract, invokes the build+test cycle, and echoes
# the final artifact directory.
#
# Usage:
#   ui-walkthrough.sh <script-path> <run-name> <sim-name> <derived-data-path>
#
# Arguments (all positional; passed through from the justfile recipe):
#   <script-path>        Path to the action-script JSON (relative to the repo root, or absolute).
#   <run-name>           Run directory name, or "" to let the recorder pick a UTC timestamp.
#   <sim-name>           Simulator destination name (e.g. "iPhone 17").
#   <derived-data-path>  DerivedData path (per-worktree isolated by the justfile).
#
# Env-var contract handed to the driver (see HanahuacUITests/UIActionScript.swift &
# UIWalkthroughRecorder.swift):
#   HANA_UI_SCRIPT_PATH  Filesystem path to the JSON action script (preferred over inline JSON).
#   HANA_REPO_ROOT       Absolute repo checkout path so artifacts land in the real `.workflow/` tree.
#   HANA_UI_RUN          Run directory name override (omitted when <run-name> is empty).
#
# IMPORTANT — env propagation: xcodebuild does NOT forward this shell's environment into the
# sandboxed XCUITest runner process. Only variables prefixed `TEST_RUNNER_` are injected into the
# runner (xcodebuild strips the prefix), so the driver sees the bare `HANA_*` names via
# `ProcessInfo.processInfo.environment`. Without this prefix the recorder falls back to the app's
# sandbox tmp dir and NOTHING lands in the repo tree.
#
# Reality check: each invocation is a compiled `xcodebuild test` cycle (tens of seconds), NOT a live
# frame-by-frame session. Write a script, run once, then read the emitted artifacts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SCRIPT_ARG="${1:-}"
RUN_NAME="${2:-}"
SIM_NAME="${3:-}"
DERIVED_DATA="${4:-}"

if [[ -z "${SCRIPT_ARG}" || -z "${SIM_NAME}" || -z "${DERIVED_DATA}" ]]; then
    echo "usage: $0 <script-path> <run-name> <sim-name> <derived-data-path>" >&2
    exit 2
fi

# Resolve the action script to an absolute path (accepts repo-relative or absolute input).
if [[ "${SCRIPT_ARG}" = /* ]]; then
    SCRIPT_PATH="${SCRIPT_ARG}"
else
    SCRIPT_PATH="${ROOT}/${SCRIPT_ARG}"
fi
if [[ ! -f "${SCRIPT_PATH}" ]]; then
    echo "ERROR: action script not found: ${SCRIPT_PATH}" >&2
    exit 1
fi

# Resolve the run name: use the caller's value, else a UTC timestamp (mirrors the recorder fallback so
# this script can print the exact artifact dir up front).
if [[ -z "${RUN_NAME}" ]]; then
    RUN_NAME="$(date -u +%Y%m%d-%H%M%S)"
fi
RUN_DIR="${ROOT}/.workflow/ui-walkthrough/${RUN_NAME}"

echo "==> UI walkthrough"
echo "    script : ${SCRIPT_PATH}"
echo "    run    : ${RUN_NAME}"
echo "    sim    : ${SIM_NAME}"
echo "    output : ${RUN_DIR}"
echo "    (each run is a compiled xcodebuild test cycle ~tens of seconds, not live frame-by-frame)"

# `TEST_RUNNER_`-prefixed vars are the ONLY ones xcodebuild injects into the sandboxed test runner
# (the prefix is stripped, so the driver reads the bare `HANA_*` names).
export TEST_RUNNER_HANA_UI_SCRIPT_PATH="${SCRIPT_PATH}"
export TEST_RUNNER_HANA_REPO_ROOT="${ROOT}"
export TEST_RUNNER_HANA_UI_RUN="${RUN_NAME}"

# Also pass the script inline. The sandboxed UI-test runner can write the artifact tree but cannot
# always READ an arbitrary host filesystem path, so the path read of HANA_UI_SCRIPT_PATH can silently
# yield zero steps. The loader prefers the path and falls back to this inline payload, so the recipe
# drives the full script regardless of the runner's host-path read access.
TEST_RUNNER_HANA_UI_SCRIPT="$(cat "${SCRIPT_PATH}")"
export TEST_RUNNER_HANA_UI_SCRIPT

xcodebuild test \
    -project "${ROOT}/Hanahuac.xcodeproj" \
    -scheme Hanahuac \
    -destination "platform=iOS Simulator,name=${SIM_NAME}" \
    -derivedDataPath "${DERIVED_DATA}" \
    -only-testing:HanahuacUITests/UIDriverTests/testRunUIScript \
    2>&1 | grep -E "TEST SUCCEEDED|TEST FAILED|error:|Test Case.*failed" || true

if [[ ! -d "${RUN_DIR}" ]]; then
    echo "ERROR: no artifact directory produced at ${RUN_DIR}" >&2
    exit 1
fi
if [[ ! -f "${RUN_DIR}/000-step.png" || ! -f "${RUN_DIR}/000-step.json" ]]; then
    echo "ERROR: initial artifacts (000-step.png + 000-step.json) missing in ${RUN_DIR}" >&2
    exit 1
fi

echo "==> Artifacts written to: ${RUN_DIR}"
