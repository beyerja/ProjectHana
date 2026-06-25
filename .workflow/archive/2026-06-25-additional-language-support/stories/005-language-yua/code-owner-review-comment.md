<!-- code-owner-review -->
## Code-owner review — round 1 — ✅ APPROVED

Independent second-eye re-verification of the Yucatec Maya (`yua`, "Màaya t'àan") downloadable-language pack. The full diff was read directly (not via the review skill); the `independent-review` verdict was input, not the conclusion. Reached an independent **APPROVED**.

Independently confirmed:
1. Content is genuine Yucatec Maya (INALI orthography: glottal apostrophe, `-o'ob` plurals, `Màaya t'àan`), not copied Spanish/English; format specifiers preserved.
2. Fallback chain is `[yua, es-MX, en]` — Mexican Spanish, not es-ES — in the catalog, `fallsBackThroughSpanish`, and tests.
3. The gap key `settings.sync.toggle` is a real omission in `yua.lproj`, present in es-MX/en, exercised by `testYucatecGapKey_resolvesToMexicanSpanishBeforeEnglish`.
4. ODR wiring excludes `yua.lproj` + `yua-geo.json` from the base bundle and tags them `[lang-yua]`; es-MX/en stay bundled; `verify-odr-packs.sh` updated.
5. No scratch `add-yua-geo.py` is committed — only the established `generate-geo-packs.py`.

Wiring is reachable end-to-end at runtime. CI green on the head (Build & Test, gitleaks success). `yua` is fallback-permitted, so incomplete content is acceptable.

Non-blocking nit (agreed): the three hand-maintained downloadable-language lists could later be catalog-derived; CI gates catch drift.

**Formal state submitted as `Hanahuac-Bot` via the wrapper; read-back confirmed `{user: Hanahuac-Bot, state: APPROVED}`.** Merge gate satisfied.
