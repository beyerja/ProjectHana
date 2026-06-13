# Story 001 — Dependabot Config

## Implementation Notes

- Created `.github/dependabot.yml`
- `github-actions` ecosystem: scans `/.github/workflows/` automatically when `directory: "/"` is set
- `swift` ecosystem: ready for when Swift packages are added; no-ops today
- Weekly schedule (Mondays 09:00 UTC) — not daily, reducing PR noise
- No auto-merge configured — all PRs require manual review (supply-chain delay satisfied)
- `open-pull-requests-limit: 5` per ecosystem prevents PR flood
- Labels: `dependencies` for easy filtering

## Status: DONE
