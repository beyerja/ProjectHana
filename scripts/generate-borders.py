#!/usr/bin/env python3
"""Generate sea-borders.json and mountain-borders.json from Natural Earth.

This reproduces the polygon-overlay data used by the map quiz for the `sea` and
`mountain` categories, the same way `country-borders.json` is derived from
Natural Earth admin-0 boundaries (see the 2026-06-11-country-borders feature).

Sources (Natural Earth, public domain):
  - Seas:      ne_50m_geography_marine_polys   (IHO "Limits of Oceans and Seas")
  - Mountains: ne_10m_geography_regions_polys  (Range/mtn features)

Each entry is matched to a Natural Earth feature by name via the curated maps
below (NE names differ from our display names, e.g. "Atlas Mountains" -> "HAUT
ATLAS"). Where a NE name is ambiguous (e.g. two "SIERRA NEVADA" ranges), the
feature nearest the entry's lat/lon in seas.json / mountains.json is chosen.

Output schema matches country-borders.json:
    [ {"id": "<our id>", "rings": [[[lon, lat], ...], ...]}, ... ]
Coordinates are rounded to COORD_DECIMALS; rings smaller than MIN_RING_AREA
(square degrees) are dropped as noise. Entries with no confident match are
omitted and rendered pin-only by the app (e.g. East African Rift Highlands).

The committed JSON is the reviewed source of truth; this script documents how it
was derived and can regenerate it. It is non-destructive by default — running it
compares freshly-derived data against the committed files and reports differences;
pass --write to actually overwrite them.

Usage:
    python3 scripts/generate-borders.py            # verify against committed (no writes)
    python3 scripts/generate-borders.py --write    # regenerate and overwrite the JSON files
Requires `pyshp` (pure-Python, no GDAL):  python3 -m pip install pyshp
"""

from __future__ import annotations

import argparse
import io
import json
import math
import os
import sys
import urllib.request
import zipfile

NE_BASE = "https://naturalearth.s3.amazonaws.com"
LAYERS = {
    "marine": "50m_physical/ne_50m_geography_marine_polys",
    "regions": "10m_physical/ne_10m_geography_regions_polys",
}
COORD_DECIMALS = 3
# Minimum ring area in square degrees, per category. Oceans are vast, so a large
# threshold keeps only the major water-body outlines (not every islet); mountain
# ranges are far smaller, so they need a much lower bar to retain real sub-ranges.
SEA_MIN_AREA = 2.0
MOUNTAIN_MIN_AREA = 0.5

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(REPO, "Hanahuac", "Resources")
CACHE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "ne-borders-cache")

# our sea id -> one or more Natural Earth marine `name` values (oceans split N/S)
SEA_MAP = {
    "pacific": ["North Pacific Ocean", "South Pacific Ocean"],
    "atlantic": ["North Atlantic Ocean", "South Atlantic Ocean"],
    "indian": ["INDIAN OCEAN"],
    "southern": ["SOUTHERN OCEAN"],
    "arctic": ["Arctic Ocean"],
    "mediterranean": ["Mediterranean Sea"],
    "caribbean": ["Caribbean Sea"],
    "south-china": ["South China Sea"],
    "bering": ["Bering Sea"],
    "gulf-of-mexico": ["Gulf of Mexico"],
    "north-sea": ["North Sea"],
    "red-sea": ["Red Sea"],
    "black-sea": ["Black Sea"],
    "caspian-sea": ["Caspian Sea"],
    "persian-gulf": ["Persian Gulf"],
    "east-china": ["East China Sea"],
    "bay-of-bengal": ["Bay of Bengal"],
    "arabian-sea": ["Arabian Sea"],
    "coral-sea": ["Coral Sea"],
    "tasman-sea": ["Tasman Sea"],
}

# our mountain id -> Natural Earth regions `NAME` (ALL-CAPS Range/mtn features)
MOUNTAIN_MAP = {
    "himalayas": "HIMALAYAS",
    "andes": "ANDES",
    "rockies": "ROCKY MOUNTAINS",
    "alps": "ALPS",
    "great-dividing-range": "GREAT DIVIDING RANGE",
    "kunlun": "KUNLUN MOUNTAINS",
    "tian-shan": "TIAN SHAN",
    "altai": "ALTAY MOUNTAINS",
    "caucasus": "CAUCASUS MTS.",
    "pyrenees": "PYRENEES",
    "carpathians": "CARPATHIAN MOUNTAINS",
    "appalachians": "APPALACHIAN MTS.",
    "atlas": "ATLAS MOUNTAINS",  # comprehensive polygon spanning the sub-ranges
    "drakensberg": "DRAKENSBERG",
    "ethiopian-highlands": "ETHIOPIAN HIGHLANDS",
    "scandinavian-mountains": "KJØLEN MOUNTAINS",
    "hindu-kush": "HINDU KUSH",
    "karakoram": "KARAKORAM RA.",
    "pamir": "PAMIRS",
    "sierra-nevada-us": "SIERRA NEVADA",  # ambiguous (US vs Spain) -> proximity
    "southern-alps": "SOUTHERN ALPS",
    "zagros": "ZAGROS MOUNTAINS",
    # eastern-rift-highlands: no confident NE polygon -> pin-only fallback
}


def fetch_layer(key: str):
    """Download+unzip a NE layer into CACHE if absent; return base path (no ext)."""
    import shapefile  # imported here so --help works without pyshp

    rel = LAYERS[key]
    base = os.path.join(CACHE, os.path.basename(rel))
    if not os.path.exists(base + ".shp"):
        os.makedirs(CACHE, exist_ok=True)
        url = f"{NE_BASE}/{rel}.zip"
        print(f"  downloading {url}")
        with urllib.request.urlopen(url, timeout=180) as r:
            zipfile.ZipFile(io.BytesIO(r.read())).extractall(CACHE)
    return shapefile.Reader(base)


def rings_from_shape(shape):
    """Split a shapefile shape into rings (one per part)."""
    idx = [*list(shape.parts), len(shape.points)]
    return [shape.points[idx[i] : idx[i + 1]] for i in range(len(idx) - 1)]


def ring_area(ring):
    a = 0.0
    for i in range(len(ring) - 1):
        a += ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1]
    return abs(a) / 2.0


def ring_centroid(ring):
    xs = [p[0] for p in ring]
    ys = [p[1] for p in ring]
    return sum(xs) / len(xs), sum(ys) / len(ys)


def clean_rings(raw_rings, min_area):
    """Drop tiny rings, round coords, sort largest-first."""
    out = []
    for r in raw_rings:
        if len(r) < 4 or ring_area(r) < min_area:
            continue
        out.append([[round(p[0], COORD_DECIMALS), round(p[1], COORD_DECIMALS)] for p in r])
    out.sort(key=ring_area, reverse=True)
    return out


def build_seas():
    reader = fetch_layer("marine")
    shapes, recs = reader.shapes(), reader.records()
    by_name = {}
    for s, rec in zip(shapes, recs, strict=False):
        by_name.setdefault(rec["name"], []).append(s)
    out = []
    for sid, names in SEA_MAP.items():
        raw = []
        for nm in names:
            for s in by_name.get(nm, []):
                raw.extend(rings_from_shape(s))
        rings = clean_rings(raw, SEA_MIN_AREA)
        if rings:
            out.append({"id": sid, "rings": rings})
        else:
            print(f"  WARN sea {sid}: no rings matched {names}")
    return out


def build_mountains():
    reader = fetch_layer("regions")
    shapes, recs = reader.shapes(), reader.records()
    coords = {e["id"]: (e["lat"], e["lon"]) for e in load_json("mountains.json")}
    by_name = {}
    for s, rec in zip(shapes, recs, strict=False):
        by_name.setdefault(rec["NAME"], []).append(s)
    out = []
    for mid, ne_name in MOUNTAIN_MAP.items():
        candidates = by_name.get(ne_name, [])
        if not candidates:
            print(f"  WARN mountain {mid}: NE name {ne_name!r} not found")
            continue
        if len(candidates) > 1 and mid in coords:
            lat, lon = coords[mid]
            candidates = [
                min(
                    candidates,
                    key=lambda s: math.dist(
                        ring_centroid(max(rings_from_shape(s), key=len)), (lon, lat)
                    ),
                )
            ]
        raw = []
        for s in candidates:
            raw.extend(rings_from_shape(s))
        rings = clean_rings(raw, MOUNTAIN_MIN_AREA)
        if rings:
            out.append({"id": mid, "rings": rings})
        else:
            print(f"  WARN mountain {mid}: {ne_name!r} produced no rings above threshold")
    return out


def load_json(name):
    with open(os.path.join(RES, name)) as f:
        return json.load(f)


def write_json(name, data):
    # one JSON object per line (matches country-borders.json / the committed files)
    path = os.path.join(RES, name)
    lines = [json.dumps(e, separators=(",", ":"), ensure_ascii=False) for e in data]
    with open(path, "w") as f:
        f.write("[\n" + ",\n".join(lines) + "\n]\n")
    print(f"  wrote {path} ({len(data)} entries, {sum(len(e['rings']) for e in data)} rings)")


def verify(name, data):
    """Compare generated data to the committed file; report, write nothing."""
    try:
        committed = {e["id"]: e for e in load_json(name)}
    except FileNotFoundError:
        print(f"  {name}: no committed file to compare")
        return
    gen = {e["id"]: e for e in data}
    only_committed = set(committed) - set(gen)
    only_gen = set(gen) - set(committed)
    print(f"  {name}: committed={len(committed)} generated={len(gen)}")
    if only_committed:
        print(f"    only in committed: {sorted(only_committed)}")
    if only_gen:
        print(f"    only in generated: {sorted(only_gen)}")
    for fid in sorted(set(gen) & set(committed)):
        cg, cc = gen[fid], committed[fid]
        gc = ring_centroid(max(cg["rings"], key=len))
        cccent = ring_centroid(max(cc["rings"], key=len))
        d = math.dist(gc, cccent)
        flag = "" if d < 0.5 else "  <-- centroid drift"
        if len(cg["rings"]) != len(cc["rings"]) or flag:
            print(
                f"    {fid}: rings gen={len(cg['rings'])} committed={len(cc['rings'])} "
                f"centroidΔ={d:.3f}{flag}"
            )


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "--write",
        action="store_true",
        help="overwrite the committed JSON files (default: verify only, write nothing)",
    )
    args = ap.parse_args()
    print("Seas:")
    seas = build_seas()
    print("Mountains:")
    mountains = build_mountains()
    if args.write:
        write_json("sea-borders.json", seas)
        write_json("mountain-borders.json", mountains)
    else:
        print("\nVerify (generated vs committed) — pass --write to overwrite:")
        verify("sea-borders.json", seas)
        verify("mountain-borders.json", mountains)


if __name__ == "__main__":
    sys.exit(main())
