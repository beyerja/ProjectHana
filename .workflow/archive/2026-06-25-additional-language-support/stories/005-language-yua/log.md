# Log — Add Yucatec Maya `yua` as a downloadable language (best-effort content, es-MX fallback)

2026-06-22 break-tasks: DONE, 11 tasks

2026-06-24 RESUMED after interruption. WIP inspected: source wiring (AppLocale case yua, catalog
descriptor [.yua,.esMX,.en], project.yml ODR tags, geo models/JSON, yua.lproj 131/156 keys best-effort,
yua-geo.json generated) was already complete. Remaining work finished:
- Added yua gap-resolution + bundle-candidate tests to L10nBundleResolutionTests.swift (routes yua →
  es-MX → en; gap key settings.sync.toggle omitted in yua, present in es-MX).
- Added yua catalog assertions to LanguageCatalogTests.swift (displayName, fallbackChain, availability,
  odrTags, downloadable list) and fixed testCatalogContainsExactly{Nine→Ten}Languages (9→10).
- Added testProgressIsolationForYucatecMaya(.yua, .esMX) to PerLanguageProgressTests.swift.
- Removed one-shot scratch script scripts/add-yua-geo.py (data already injected into JSON; not durable
  tooling — generate-geo-packs.py is the durable path).
Gate: just lint PASS, just test PASS (TEST SUCCEEDED), geo-packs-check PASS, verify-odr-packs PASS,
verify-base-only PASS, build-mac BUILD SUCCEEDED. Committing → PR → review → merge.

2026-06-24 independent-review: APPROVED — yua pack: genuine Maya content, [yua,es-MX,en] chain verified, real gap-key fallback, ODR-tagged not bundled, gates pass; 1 non-blocking nit (catalog-derive packLanguages).

2026-06-24 code-owner-review: APPROVED — independent second-eye re-verification of diff: genuine Yucatec Maya (INALI orthography, not copied es/en), fallback chain [yua,es-MX,en] (es-MX not es-ES), real gap key settings.sync.toggle, ODR excludes yua from base bundle, no scratch add-yua-geo.py committed; CI green on head (Build & Test + gitleaks success), no re-trigger needed. Formal Hanahuac-Bot APPROVE submitted via gh-review-bot.sh wrapper; read-back confirmed {user: Hanahuac-Bot, state: APPROVED}. Merge gate satisfied.

2026-06-24 merge-pr: DONE
