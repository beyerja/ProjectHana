# Story 002 — Nix flake.lock Update Workflow

## Implementation Notes

- Created `.github/workflows/update-flake-lock.yml`
- Runs on weekly cron (Sundays 02:00 UTC) + `workflow_dispatch` for manual triggers
- Uses `DeterminateSystems/nix-installer-action@v22` (latest) to install Nix on ubuntu-latest runner
- Runs `nix flake update` — creates `flake.lock` if absent (bootstrap), updates it if present
- Uses `peter-evans/create-pull-request@v8` (latest) to open a PR on branch `automated/update-flake-lock`
- No auto-merge step — PR requires human approval
- PR body explains the supply-chain safety rationale
- `permissions: contents: write, pull-requests: write` required for create-pull-request action

## Action versions used
- `actions/checkout@v6` (matches ci.yml)
- `DeterminateSystems/nix-installer-action@v22` (latest as of 2026-06-13)
- `peter-evans/create-pull-request@v8` (latest as of 2026-06-13)

## Status: DONE
