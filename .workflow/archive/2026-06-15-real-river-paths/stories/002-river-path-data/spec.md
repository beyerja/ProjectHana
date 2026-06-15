# Story 002 — Reproducible river-path data from Natural Earth

## Goal
Add the real river-centerline geometry that story 001's loader consumes: a committed,
documented, non-destructive generation script plus the generated `river-paths.json`.
Once bundled, rivers render along their real course instead of the straight fallback.

## Acceptance Criteria
- [ ] `scripts/generate-river-paths.py` follows the `generate-borders.py` pattern exactly:
      downloads `ne_10m_rivers_lake_centerlines`, matches our 32 river ids to NE features
      via a curated id→NE-name map, gathers all segments sharing a river name, stitches
      them into an ordered path (source→mouth where determinable), rounds coords to 3 dp,
      writes one JSON object per line. Verify-by-default; `--write` to regenerate. Pure
      Python (`pyshp`), no GDAL.
- [ ] Curated map handles the special cases: `yellow` → **Huang He**; `dnieper` matched
      via NE `name_en`/`name_alt` (e.g. Dnipro/Dnieper), explicitly NOT Dniester;
      Irrawaddy captures the **main river** (filter out delta-only segments);
      Amazon→Amazonas, Yenisei→Yenisey, Senegal→Sénégal.
- [ ] Generated `Hanahuac/Resources/river-paths.json` covers every river NE matches
      (target 31/32). Each entry is `{"id": "...", "parts": [[[lon,lat],...],...]}`
      (or single `path`), ordered, with sane vertex counts (>2). Rivers NE cannot match
      are omitted from the JSON and rely on story 001's straight-line fallback; the
      script prints a WARN for each omission and the spec/tests record which rivers fall
      back.
- [ ] `river-paths.json` added to `Hanahuac/Resources/` and `just generate` run so it is
      bundled (pbxproj never hand-edited). `RiverPathLoader.shared` now returns real
      paths.
- [ ] Stitching is deterministic and ordered: adjacent segments are chained by nearest
      endpoint, oriented so the path runs from the end nearest the river's stored source
      to the end nearest its mouth.
- [ ] `just test` passes. App build includes the bundled JSON. A test asserts a known
      major river (e.g. Nile or Amazon) now has a multi-vertex path (>2 points) from the
      loader.

## Notes
- Reuse `generate-borders.py` helpers where sensible (download/cache, rounding, JSON
  writer); a sibling script is fine per the user's guidance.
- The committed JSON is the reviewed source of truth — running the script with no flags
  must report the committed file matches (or report drift), writing nothing.
