<!-- code-owner-review -->
## Code-owner review — merge gate

**Verdict: APPROVED** — `code-owner-review` check posted with conclusion `success` on head `546b11e` (check-run id `86409744089`, App id `4144849`; read-back verified).

Independent second-eye confirmation (diff reviewed directly, not via /code-review):

- All 9 acceptance criteria of story 004 traced through the diff: triggers/dry-run semantics (gate (a) and publish `if:` expressions are exact complements; `inputs.dry_run` is false on tag push), gates (a)–(g) in spec order reusing story-002 scripts and existing `just` recipes, unsigned archive/ipa + `SHA256SUMS.txt` via the story-003-proven `just archive`, Release creation with `--verify-tag --notes-file --generate-notes` and prerelease detection, credential-gated App Store placeholders with a complementary explanatory skip step, macos-15 + Nix + minimal permissions + per-ref concurrency, and zero changes to the per-PR blocking check set.
- `extract-changelog-section.sh` logic independently verified: the awk prefix match cannot confuse `1.0.0` with `1.0.10` or a prerelease heading; strict-semver validation; empty/whitespace-only bodies rejected; fixture-only tests wired into `just test-release-scripts`.
- No enforcement test weakened anywhere in the diff.
- The first reviewer's two non-blocking findings concur as non-blocking: the empty-body failure surfaces late but still fails the publish job before any Release exists; the `read_marketing_version` duplication is follow-up material.
- CI: all 4 checks green on `546b11e`; `mergeStateStatus` was `BLOCKED` only on this gate check (not `BEHIND`).
