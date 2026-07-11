**[non-blocking] Empty-body CHANGELOG section fails only at publish time, after ~90 min of gates.**

Gate (b) (`check-changelog.sh`) verifies only that the `## [X.Y.Z]` *heading* exists, while `extract-changelog-section.sh` (run in the publish job) additionally rejects an empty/whitespace-only section body. So a tag pushed with a present-but-empty CHANGELOG section passes every gate, burns the full macOS gates job, and then fails in "Build release body from CHANGELOG" — with the tag already pushed and no Release created. Nothing wrong is published (the run fails loudly), but the failure surfaces at the most expensive possible point, and a dry-run never exercises this path at all (the publish job is skipped wholesale).

Suggestion: front-load the empty-body rule into gate (b), e.g. run `bash scripts/extract-changelog-section.sh "$base" > /dev/null` alongside (or instead of) `check-changelog.sh` — same cheap cost, and dry-runs would then validate the release body too.
