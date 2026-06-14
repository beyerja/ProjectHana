# Feature: Free Security Scanning with Full CI Integration

## Goal

Add free, automated security scanning to the Hanahuac repository, fully integrated into
CI so that relevant pull requests are scanned and security findings block (or are otherwise
guaranteed to be addressed before) merge. Use one tool per security concern — no two
scanners covering the same thing — and add only scanners that scan something relevant to
this project.

## Context & Scanner Selection (decided from repo inspection)

The repo was inspected to decide which scanners are applicable:

- **Language/platform**: Swift / SwiftUI iOS app (Hanahuac), Xcode project generated from
  `project.yml` via XcodeGen, built on `macos-15` runners with `xcodebuild`.
- **Dependencies (SCA)**: `project.yml` declares `dependencies: []`; there is **no**
  `Package.swift`, **no** `Package.resolved`, and **zero** remote SPM package references in
  the Xcode project. Therefore software-composition / dependency scanning has nothing to
  scan and is **out of scope** (adding it would be a no-op scanner).
- **Repo visibility**: PUBLIC → CodeQL and GitHub native security features are free.

Selected scanners (one per concern, all free for public repos, verified latest major
action versions on 2026-06-14):

| Concern         | Tool                              | Action (latest major) | Blocking policy |
|-----------------|-----------------------------------|-----------------------|-----------------|
| SAST (code)     | CodeQL (Swift)                    | `github/codeql-action@v4` | Block PR on high-severity (error) code-scanning alerts |
| Secret scanning | gitleaks                          | `gitleaks/gitleaks-action@v3` | Hard-block: any leaked secret fails the check |
| Dependency/SCA  | none (no dependencies to scan)    | —                     | N/A — out of scope |

CodeQL fully supports Swift (Swift 6.x as of CodeQL 2.25.x; this project uses Swift 5.10).
gitleaks-action v3 is free for public repositories.

## Acceptance Criteria

- [ ] A CodeQL workflow exists at `.github/workflows/codeql.yml` that analyzes the Swift
      code, builds via the project's `just`/`xcodebuild` toolchain on `macos-15`, runs on
      pull requests targeting `main` and on pushes to `main`, and uploads results to the
      GitHub Security tab.
- [ ] A secret-scanning workflow exists (gitleaks) that runs on pull requests targeting
      `main` and on pushes to `main`, and fails the check if a secret is detected.
- [ ] Both scanners run on all relevant PRs (any PR that touches Swift source or workflow
      files), and their checks are configured so that findings block merge — secrets always
      block; CodeQL blocks on high-severity findings. Where hard-blocking every CodeQL
      finding would be too strict, lower-severity findings are still surfaced in the
      Security tab and tracked, never silently dropped.
- [ ] No duplicate scanners: exactly one tool per concern; no dependency scanner is added
      because there are no dependencies to scan.
- [ ] All GitHub Actions are pinned to the latest verified major version (checked at
      authoring time, not assumed from training data). No hardcoded `/nix/...` paths in any
      workflow or script.
- [ ] Existing CI (build & test) continues to pass; the new workflows do not break the
      existing `ci.yml`.
- [ ] Branch protection / required status checks on `main` are documented and, where the
      tooling allows via `gh`, configured so the security checks are required to merge. If
      configuration requires the repo owner to act in the GitHub UI, provide exact
      step-by-step instructions in repo docs.

## Constraints

- No paid services. Everything must be free for a public repo.
- One tool per concern; no duplicate coverage.
- Honor project memory: do not assume GitHub Actions versions — pin to the latest verified
  major; never hardcode `/nix/...` paths (use flake + direnv / `just`).
- Xcode project is generated from `project.yml`; never hand-edit `project.pbxproj`.
- Blocking is preferred; if hard-blocking a given scanner is judged too strict, choose an
  alternative that still guarantees findings are addressed (e.g. block on high-severity,
  surface the rest in the Security tab with tracked alerts).

## Out of Scope

- Dependency / software-composition analysis (SCA) — no dependencies exist to scan.
- Paid SAST/DAST platforms or any tool requiring a paid plan.
- Container/IaC scanning — the project ships no containers or infrastructure-as-code.
- Runtime/DAST scanning of the iOS app.
