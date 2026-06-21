#!/usr/bin/env bash
# install-hooks.sh — activate this repo's committed git hooks.
#
# The hooks live in the version-controlled `.githooks/` directory (pre-commit, pre-push). Git only
# runs them if `core.hooksPath` points there, so a fresh clone runs this once (or `just install-hooks`)
# to set that config. The committed `.githooks/pre-commit` composes the main-branch guard with the
# defense-in-depth secret scan; no per-clone shim is installed (and none is needed). Idempotent:
# re-running just re-asserts the config.
set -euo pipefail

# Resolve the repository root from this script's location so it works from any CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

HOOKS_DIR=".githooks"

if [[ ! -d "${REPO_ROOT}/${HOOKS_DIR}" ]]; then
    echo "ERROR: ${HOOKS_DIR}/ not found in ${REPO_ROOT}; cannot activate committed hooks." >&2
    exit 1
fi

# Point git at the committed hooks dir (idempotent). A repo-relative value keeps it valid across
# clones and worktrees regardless of where the repo lives on disk.
git -C "${REPO_ROOT}" config core.hooksPath "${HOOKS_DIR}"

current="$(git -C "${REPO_ROOT}" config --get core.hooksPath || true)"
echo "Activated committed git hooks: core.hooksPath=${current}"
echo "  pre-commit: blocks commits to 'main' + scans staged content for GitHub tokens"
echo "  pre-push:   blocks direct pushes to 'main'"
