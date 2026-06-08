# Story 009: GitHub Actions CI

## Title
Add GitHub Actions workflow for build and test on every push and pull request

## Goal
Provide automated quality gates so every code change is validated before merging.

## Acceptance Criteria
- [ ] `.github/workflows/ci.yml` exists and is valid YAML
- [ ] Workflow triggers on: push to `main`, pull_request targeting `main`
- [ ] Job runs on `macos-15` (Xcode 16 pre-installed) or `macos-latest`
- [ ] Build step: `xcodebuild build -scheme ProjectHana -destination 'platform=iOS Simulator,
      name=iPhone 16,OS=latest'` exits 0
- [ ] Test step: `xcodebuild test -scheme ProjectHana -destination 'platform=iOS Simulator,
      name=iPhone 16,OS=latest'` exits 0
- [ ] Workflow uses `set -o pipefail` or equivalent so partial failures are caught
- [ ] A `README.md` badge shows CI status (GitHub Actions build badge)
- [ ] The workflow completes successfully on the first push after this story is merged (verified
      by checking the Actions tab or CI output)
