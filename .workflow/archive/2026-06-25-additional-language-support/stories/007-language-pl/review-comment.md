<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context 4-eye review of the Polish (`pl`) COMPLETE-content language addition. Verdict: **APPROVED** — correctness and Polish content completeness/quality both verified, not just compilation.

### Objective gates (all green locally)
- `just l10n-check` — **PASS**: `pl` carries all **156/156** canonical UI keys; zero missing, zero extra. Format-specifier parity vs `en` is exact (`%d`/`%@`/positional) across all 156 keys.
- `just geo-packs-check` — **PASS**: committed `pl-geo.json` (272 entries: 197 countries + 32 rivers + 23 mountains + 20 seas; 197 capitals) is up to date with source data.
- `just verify-odr-packs` — **PASS**: `lang-pl` → `pl.lproj` + `pl-geo.json`, data-only, base langs untagged.

### Content completeness & quality (the real bar)
- **Geo coverage**: every country has `name_pl` + `capital_pl` (197/197); every river/mountain/sea has `name_pl` (no gaps, no placeholders, no English leakage).
- **Established Polish exonyms** present and correct: Niemcy, Hiszpania, Włochy, Chiny, Francja, Rosja; Pekin, Moskwa, Londyn, Paryż, Wiedeń, Kair, Tokio, Madryt, Sztokholm, Stany Zjednoczone; rivers Nil/Amazonka/Wołga/Eufrat/Tygrys/Ren/Dunaj/Dniepr; ranges Himalaje/Andy/Alpy/Pireneje/Karpaty/Kaukaz; seas Morze Śródziemne/Ocean Spokojny/Morze Czarne/Zatoka Perska. Where no exonym exists (Murray, Mekong, Niger, Sierra Nevada) the original is correctly retained.
- **UI strings**: native, professional Polish with correct diacritics (ą ć ę ł ń ó ś ź ż), Polish typographic quotes („…"), comma decimals (`EF ≥ 2,0`), and singular/plural card forms. No machine-garble, no English/other-language leakage.

### Wiring & invariants
- `AppLocale.pl` placed after `it`, before `ko`; catalog descriptor displayName "Polski", fallbackChain `[.pl, .en]` (COMPLETE → straight to en, not via Spanish), availability `.downloadablePack`, odrTags `[lang-pl]`.
- `GeoModel+PackData` `.pl` arms + `Country/River/MountainRange/Sea` `namePl`/`capitalPl` mirror Italian.
- `check-l10n-completeness.py` (`pl` in FULL_LOCALES), `generate-geo-packs.py` (PACK_LANGUAGES + SUFFIX_BY_CODE), `verify-odr-packs.sh` / `verify-base-only-bundle.sh`, `project.yml` (excludes + `[lang-pl]`), and regenerated `project.pbxproj` all updated consistently.
- Tests: count → **12** (`testCatalogContainsExactlyTwelveLanguages`, `testAllCasesCount` = 12), plus display-name, downloadablePackLanguages, odrTags, fallback-chain `[pl,en]`, bundle-candidates, `matching()` auto-detect (es-* unperturbed), and per-language progress isolation.
- `scripts/seed-pl-geo.py` is committed — consistent with merged precedent (`seed-it-geo.py`, `seed-es-es-geo.py`); not flagged.

No blocking findings. The formal code-owner review is submitted by the next agent.
