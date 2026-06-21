# Log — 002 — `LanguagePackProvider` seam + bundled provider + geo-name pack data model

2026-06-20 break-tasks: DONE, 9 tasks
2026-06-20 implement-story: DONE — tasks 001-009 (GeoNamePackData + loader + LanguagePackProvider seam + BundledLanguagePackProvider + GeoNameResolver model refactor + tests); lint+test green, no retries on tests
2026-06-20 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/116
2026-06-20 merge-pr: DONE — squash-merged PR #116 into feat/downloadable-language-packs (merge commit 0d88fff)
2026-06-20 verify-story: DONE — all 7 acceptance criteria satisfied. LanguagePackProvider protocol (stringBundle/geoNameData/state) + LanguagePackState seam; BundledLanguagePackProvider always .available, drops invalid packs; versioned schema-validated GeoNamePackData/GeoNamePackLoader (typed errors, decodeOrNil, never fatalError); geo models route localizedName/localizedCapital through GeoNameResolver keyed by code (no per-locale switch in localized accessors); pack data is JSON-only with no network/crypto code (only doc-comments reference future Ed25519/SHA-256/CDN); new tests cover bundled provider, schema validation incl. malformed degradation, and resolver. lint + full test suite green (TEST SUCCEEDED).
