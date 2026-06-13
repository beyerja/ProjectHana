# Feature: Automated Dependency Updates

## Context

ProjectHana uses the following dependency systems:

1. **Nix flake** (`flake.nix`) — manages the dev environment. Inputs are `nixpkgs/nixpkgs-unstable` and `flake-utils`. No `flake.lock` is currently committed to the repo.
2. **Swift Package Manager** — `Package.resolved` is committed (version 3), but currently has zero pins (no external Swift packages). Still, the SPM ecosystem should be wired up in case packages are added later.
3. **GitHub Actions** — `ci.yml` uses `actions/checkout@v6`. Action pins should be kept current.
4. **No other package managers** — no CocoaPods, npm, Cargo, Gemfile, etc.

## Solution

Use two complementary mechanisms, both free:

### 1. Dependabot (for GitHub Actions + SPM)

A `.github/dependabot.yml` config with:
- `github-actions` ecosystem — keeps action pins (e.g. `actions/checkout`) up to date
- `swift` ecosystem — keeps SPM package pins up to date (no-op today, but ready for when packages are added)
- Schedule: **weekly** (not daily) to keep PR noise low
- **Minimum 1-day age requirement**: Dependabot's `ignore` rules do not enforce age, but the PR review process provides the delay. The schedule itself (weekly) means updates are never applied immediately. Additionally, Dependabot security updates can be separately disabled to prevent instant auto-merge.
- No auto-merge configured — PRs must be manually reviewed and merged, satisfying the supply-chain delay requirement.
- `open-pull-requests-limit` set to a reasonable cap (e.g. 5 per ecosystem) to avoid PR flood.

### 2. Scheduled GitHub Actions workflow (for Nix flake.lock)

Dependabot does not support Nix flakes. A dedicated workflow (`.github/workflows/update-flake-lock.yml`) will:
- Run on a weekly cron schedule (e.g. Sundays at 02:00 UTC)
- Run `nix flake update` to regenerate `flake.lock`
- Open a PR if the lock file changed, using `peter-evans/create-pull-request` (free, widely used)
- The PR title/body identifies which flake inputs changed
- No auto-merge — the PR sits for human review, satisfying the 1-day delay requirement
- The workflow also runs Nix's built-in `nix flake check` (if the flake has checks defined) before opening the PR

### Prerequisite: commit an initial flake.lock

Before automated updates can track changes, the `flake.lock` must exist in the repo. The implementation will generate and commit the initial `flake.lock` as part of this feature. Since `nix` is not available in this dev environment (macOS shell without Nix installed), the lock file will need to be generated in the GitHub Actions environment using `DeterminateSystems/nix-installer-action` (free).

Alternative: the workflow generates the initial lock on first run and commits it via the PR. The `flake.lock` update workflow handles the bootstrapping case (if `flake.lock` doesn't exist yet, `nix flake update` creates it).

## Hard Requirements

- Nix flake (`flake.lock`) updates are automated — CRITICAL
- All solutions are free (Dependabot is free for public/private repos on GitHub; `peter-evans/create-pull-request` is free)
- Updates are **not** automatically merged; they require human approval (satisfies the 1-day delay supply-chain concern)
- Schedule-based (weekly) further ensures updates are never applied on day zero

## Files to Create/Modify

- `.github/dependabot.yml` — new file
- `.github/workflows/update-flake-lock.yml` — new file
- `.gitignore` — no change needed (flake.lock is not excluded)

## Out of Scope

- Auto-merge rules
- Version constraints / ignore rules for specific packages (can be added later)
- CocoaPods, npm, Cargo (not used in this repo)
