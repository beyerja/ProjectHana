# Stories — safe-stable-releases

Ordered by dependency; each story is independently mergeable via the normal
CI + SHA-bound `code-owner-review` gate. Branches: `story/safe-stable-releases/<nnn>-<name>`.

## Stories
- [x] 001-versioning-bump-tooling: Deterministic semver versioning with a scripted `just bump` procedure
- [x] 002-changelog-and-consistency-checks: Keep-a-Changelog `CHANGELOG.md` plus scripted changelog/version consistency checks
- [x] 003-unsigned-archive-proof-local-tooling: Prove the unsigned Release archive path empirically; deliver `just archive` and `just release-check`
- [x] 004-release-workflow: `.github/workflows/release.yml`: gated, unsigned, artifact-producing release pipeline
- [x] 005-releasing-docs-dry-run: `docs/releasing.md` runbook and a green `workflow_dispatch` dry-run of `release.yml`
