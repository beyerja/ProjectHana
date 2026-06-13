# Stories

## Story 001 — Add Dependabot configuration
- **Dir**: `.workflow/stories/001-dependabot-config`
- **Status**: done

**Problem**: No automated dependency updates exist for GitHub Actions pins (e.g. `actions/checkout@v6`) or Swift Package Manager packages. If Swift packages are added in the future, they will never receive automated update PRs.

**Fix**: Create `.github/dependabot.yml` with:
- `github-actions` ecosystem targeting `.github/workflows`; weekly schedule (Mondays 09:00 UTC); open-pull-requests-limit 5
- `swift` ecosystem targeting the repo root; weekly schedule (Mondays 09:00 UTC); open-pull-requests-limit 5
- No auto-merge — PRs must be manually reviewed (satisfies the supply-chain delay requirement)

**Files to create**:
- `.github/dependabot.yml`

**Acceptance criteria**:
- `.github/dependabot.yml` is valid YAML and passes `gh` schema checks (or manual review)
- Both `github-actions` and `swift` ecosystems are configured
- Schedule is weekly (not daily/hourly)
- No auto-merge rules are configured

---

## Story 002 — Add Nix flake.lock update workflow
- **Dir**: `.workflow/stories/002-nix-flake-update-workflow`
- **Status**: done

**Problem**: Dependabot does not support Nix flakes. The `flake.lock` (which pins exact revisions of `nixpkgs` and `flake-utils`) has no automated update mechanism. Without one, the Nix dev environment will silently fall behind upstream and receive security fixes late.

**Fix**: Create `.github/workflows/update-flake-lock.yml` that:
1. Runs on a weekly cron (Sundays 02:00 UTC) and can also be triggered manually (`workflow_dispatch`)
2. Installs Nix using `DeterminateSystems/nix-installer-action` (free, widely used)
3. Runs `nix flake update` to regenerate (or create) `flake.lock`
4. If `flake.lock` changed (or is new), opens a PR using `peter-evans/create-pull-request` with:
   - Title: "chore(nix): update flake.lock"
   - Body including which inputs changed
   - Branch name: `automated/update-flake-lock`
   - Labels: `dependencies`
5. No auto-merge — PR requires human approval before merging

Also commit an initial `flake.lock` to the repository by running the workflow's logic locally... but since Nix is not available locally, the initial `flake.lock` will be bootstrapped on the first automated workflow run. Add a note in the PR body when it is a bootstrap (first-time creation).

**Files to create**:
- `.github/workflows/update-flake-lock.yml`

**Acceptance criteria**:
- Workflow YAML is valid
- Cron schedule is weekly (not daily)
- Uses `DeterminateSystems/nix-installer-action` to install Nix
- Runs `nix flake update`
- Creates a PR via `peter-evans/create-pull-request` if `flake.lock` changed
- No auto-merge step present
- `workflow_dispatch` trigger present for manual runs
