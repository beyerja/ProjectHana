# Security

This document describes the automated security scanning configured for this repository, the
blocking policy for each scanner, and how to triage findings.

## Scanners

One tool per security concern — no two scanners cover the same thing. Only scanners that have
something relevant to scan in this project are enabled.

| Concern         | Tool    | Workflow                        | Action pin                      | Runs on                                   | Gates PR merge? |
|-----------------|---------|---------------------------------|---------------------------------|-------------------------------------------|-----------------|
| SAST (code)     | CodeQL (Swift) | `.github/workflows/codeql.yml`  | `github/codeql-action@v4`       | weekly schedule + push to `main`          | No (see below)  |
| Secret scanning | gitleaks       | `.github/workflows/secret-scan.yml` | `gitleaks/gitleaks-action@v3` | every PR to `main` + push to `main`       | Yes — hard block |
| Dependency / SCA | none          | —                               | —                               | —                                         | N/A             |

### Why no dependency (SCA) scanner?

The Xcode project (`project.yml`) declares `dependencies: []`. There is no `Package.swift`,
no `Package.resolved`, and no remote Swift Package Manager references in the Xcode project.
With zero third-party dependencies there is nothing for a software-composition scanner to
analyze, so adding one would be a no-op. If dependencies are added later, add exactly one SCA
scanner at that point.

## Blocking policy — split by speed, not by importance

Contributors must not have to wait on slow analysis for every PR, yet every finding must be
reliably addressed. Scanners are therefore split by how long they take:

- **Fast scanners block PRs.** gitleaks runs in seconds. It runs on every pull request and on
  push to `main`, and any detected secret fails the check and blocks merge.
- **Slow scanners do not block PRs.** CodeQL Swift analysis must build the app with
  `xcodebuild` on a macOS runner and takes **over 20 minutes**. Gating every PR on it would
  cripple throughput. CodeQL instead runs on a **weekly schedule** and on **push to `main`**.
  Its findings are uploaded to the **Security → Code scanning alerts** tab, where they are
  tracked and triaged over time. Findings are never silently dropped — they persist as alerts
  until resolved or dismissed with a reason.

## Triaging findings

- **Secret scanning (gitleaks):** a failed `gitleaks` PR check means a secret pattern was
  detected in the diff or branch history. Rotate the exposed credential immediately, remove it
  from the code (use a secret manager or CI secret instead), and rewrite history if the secret
  was committed. Re-run the check after the fix.
- **CodeQL:** open **Security → Code scanning alerts** in the GitHub UI. Each alert links to
  the offending code, a severity, and remediation guidance. Fix high-severity alerts promptly;
  for false positives, dismiss the alert with a documented reason. Because CodeQL re-runs on
  every push to `main` and weekly, fixes are reflected on the next run.

## Required status checks (repo owner action)

Branch protection on `main` has been configured with the following required checks (strict
mode — branches must be up to date before merging):

- `gitleaks` (secret scanning — fast, blocking)
- `Build & Test` (existing CI)

The slow CodeQL scan is intentionally NOT a required check. The steps below document how to
reproduce or adjust this configuration.

Required checks for `main`:

- `gitleaks` (secret scanning — fast, blocking)
- `Build & Test` (existing CI)

Do **not** add `Analyze (swift)` (CodeQL) as a required check — it does not run on PRs and
would block merges indefinitely waiting for a check that never reports.

### Option A — GitHub UI (recommended)

1. Go to **Settings → Branches → Add branch protection rule** (or edit the rule for `main`).
2. Set **Branch name pattern** to `main`.
3. Enable **Require status checks to pass before merging**.
4. Enable **Require branches to be up to date before merging** (optional but recommended).
5. In the status-checks search box, add: **`gitleaks`** and **`Build & Test`**.
   - These names appear only after each check has run at least once on a PR. If you don't see
     them, open any PR so the checks run, then return here.
6. Save the rule.

### Option B — `gh` CLI (non-interactive)

```sh
gh api -X PUT repos/OWNER/REPO/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  -f 'required_status_checks[strict]=true' \
  -f 'required_status_checks[checks][][context]=gitleaks' \
  -f 'required_status_checks[checks][][context]=Build & Test' \
  -F 'enforce_admins=false' \
  -F 'required_pull_request_reviews=null' \
  -F 'restrictions=null'
```

Replace `OWNER/REPO`. This requires admin permission on the repository. The check contexts
must have run at least once for GitHub to recognize them.

### Code-scanning merge protection (optional, for CodeQL)

Although CodeQL is not a per-PR check here, GitHub can still block merges when code-scanning
alerts of a chosen severity exist on the PR's diff: **Settings → Code security → Code scanning →
Protection rules → set a severity threshold**. Use this only if you accept that PRs touching
analyzed code may need a fresh CodeQL run; given the >20 min runtime, this repo leaves it off
and relies on the scheduled/push-to-main scans plus alert triage instead.

## Pinned action versions

Pinned to the latest verified major versions at authoring time (checked, not assumed):

- `github/codeql-action@v4`
- `gitleaks/gitleaks-action@v3`
- `actions/checkout@v6`

No `/nix/...` paths are hardcoded in any workflow; the toolchain comes from the macOS runner's
system Xcode and the project's `just`/flake setup.
