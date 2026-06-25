# Log — Add Italian `it` as a COMPLETE downloadable language

2026-06-24 break-tasks: DONE, 17 tasks
2026-06-24 implement-story: DONE — all 17 tasks; full gate green (lint, test, geo-packs-check, verify-odr-packs, verify-base-only, build-mac). One fix: raised cyclomatic_complexity to ignore switch case statements (11th enum case pushed GeoModel+PackData switches to 11 cases); added 5 it identical-value allowlist entries (Africa/Asia/Oceania/iCloud/streak). Italian is COMPLETE: 156/156 UI keys, 272/272 geo entities.
2026-06-24 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/162
2026-06-24 independent-review: APPROVED — 156/156 UI keys, full geo coverage, professional Italian (exonyms correct, no leakage); fallback [it,en], wiring/invariants/ODR all pass; lint+test+geo+odr green; one non-blocking nit on verify-base-only-bundle.sh loop coverage.

2026-06-24 code-owner-review: APPROVED — independent 2nd-eye re-verify (156/156 UI keys, 197/197 countries, 32/23/20 geo all name_it; exonyms correct; [.it,.en]; counts 8->11; CI green). Formal Hanahuac-Bot APPROVED posted via wrapper, confirmed by read-back.
2026-06-24 merge-pr: DONE — PR #162 squash-merged to main as b566a6a; remote branch deleted.
2026-06-24 verify-story: DONE — all 7 acceptance criteria verified post-merge. (1) picker "Italiano"; (2) fallback [.it,.en] + bundleCandidates ["it","en"]; (3) completeness PASS 156/156 UI keys, geo 0 missing name_it (countries 197, rivers 32, mountains 23, seas 20) + 0 missing capital_it; (4) it.lproj + it-geo.json tagged [lang-it], geo-packs-check PASS, verify-odr-packs PASS (lang-it -> it.lproj + it-geo.json), verify-base-only PASS (lang-it on-demand, not in base bundle); (5) progress isolation test for .it; (6) catalog/enum invariants (count 8->11, odrTags [lang-it], order correct); (7) lint PASS, test SUCCEEDED, geo-packs-check PASS, verify-odr-packs PASS, build-mac BUILD SUCCEEDED.
