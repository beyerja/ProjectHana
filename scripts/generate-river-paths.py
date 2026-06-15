#!/usr/bin/env python3
"""Generate river-paths.json from Natural Earth river centerlines.

This adds real, multi-point river-course geometry for the map quiz `river`
category, the same reproducible-data way `country-borders.json` and the
sea/mountain borders are derived from Natural Earth (see generate-borders.py).

Source (Natural Earth, public domain):
  - ne_10m_rivers_lake_centerlines  (10m physical river/lake centerlines)

Natural Earth splits each river into MANY short line segments (≈1473 features /
≈1082 names). For each of our 32 rivers we:
  1. Match NE segments by name against a curated set of acceptable NE names
     (matching `name`, `name_en`, and `name_alt`, case/accent-insensitive). NE
     display names differ from ours, e.g. Yellow River -> "Huang He",
     Amazon -> "Amazonas". Dnieper is matched via its NE alt names (Dnipro/
     Dnieper) and is explicitly NOT allowed to match "Dniester" (a different
     river). Irrawaddy excludes the delta-only segments so we keep the main river.
  2. Stitch the matched segments into one ordered path by repeatedly chaining the
     segment whose endpoint is nearest the current path tail, then orient the
     whole path so it runs from the end nearest our stored source to the end
     nearest our stored mouth. Segments too far from any current chain end start a
     new part (genuinely disjoint/braided rivers keep multiple parts).
  3. Round coordinates to COORD_DECIMALS and drop near-duplicate consecutive
     vertices.

Output schema (one object per line):
    [ {"id": "<our id>", "parts": [[[lon, lat], ...], ...]}, ... ]
Rivers with no confident NE match are OMITTED; the app falls back to the straight
source->mouth line for them (River.linePath in MappableFeature.swift). The script
prints a WARN for each omission.

The committed JSON is the reviewed source of truth; this script documents how it
was derived and can regenerate it. Non-destructive by default — it compares
freshly-derived data against the committed file and reports differences; pass
--write to overwrite.

Usage:
    python3 scripts/generate-river-paths.py            # verify against committed (no writes)
    python3 scripts/generate-river-paths.py --write    # regenerate and overwrite
Requires `pyshp` (pure-Python, no GDAL):  python3 -m pip install pyshp
"""
from __future__ import annotations
import argparse, io, json, math, os, sys, unicodedata, urllib.request, zipfile

NE_BASE = "https://naturalearth.s3.amazonaws.com"
LAYER = "10m_physical/ne_10m_rivers_lake_centerlines"
COORD_DECIMALS = 3
# Max gap (degrees) between a segment endpoint and a chain end for them to join.
# NE segments share exact endpoints, but rounding/gaps mean we allow a little slack.
JOIN_TOLERANCE = 1.5
# Consecutive vertices closer than this (degrees) are de-duplicated.
DEDUP_EPS = 0.0005

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(REPO, "Hanahuac", "Resources")
CACHE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "ne-borders-cache")

# our river id -> curated match spec. `names` is the set of acceptable NE names
# (matched against name/name_en/name_alt, normalized). `rivernums` matches NE's
# stable `rivernum` id instead — used where the display name is ambiguous or
# differs (the Yellow River is NE `name`="Huang" / rivernum 66+95, NOT "Huang He"
# as a string; matching by name would also risk catching "Yellowstone"). `exclude`
# is an optional set of substrings that, if present in a matched name, reject the
# segment (e.g. Irrawaddy delta, Dniester guard). Rivers omitted here are left to
# the app's straight-line fallback.
RIVER_MAP = {
    "nile":          {"names": ["nile", "white nile", "bahr el jebel", "albert nile", "victoria nile"]},
    "amazon":        {"names": ["amazon", "amazonas", "solimoes", "solimões", "rio amazonas"]},
    "yangtze":       {"names": ["yangtze", "chang jiang", "jinsha jiang", "tongtian", "yangtze kiang"]},
    "mississippi":   {"names": ["mississippi"]},
    "yenisei":       {"names": ["yenisey", "yenisei", "jenissej", "ulug-khem", "yenisai"]},
    # Yellow River: NE calls it "Huang" (name) with rivernum 66 (Tibetan-plateau
    # stem) + 95 (lower reach to the Bohai mouth). Matched by rivernum to be exact
    # and to avoid catching "Yellowstone".
    "yellow-river":  {"rivernums": [66, 95]},
    "ob":            {"names": ["ob", "ob'", "katun"]},
    "congo":         {"names": ["congo", "lualaba", "zaire"]},
    "lena":          {"names": ["lena"]},
    "niger":         {"names": ["niger"]},
    "mekong":        {"names": ["mekong", "lancang jiang", "lan-ts'ang chiang", "lancang"]},
    "missouri":      {"names": ["missouri"]},
    "volga":         {"names": ["volga"]},
    "zambezi":       {"names": ["zambezi", "zambeze"]},
    "ganges":        {"names": ["ganges", "ganga"]},
    "indus":         {"names": ["indus"]},
    "murray":        {"names": ["murray"]},
    "euphrates":     {"names": ["euphrates", "firat", "fırat", "al furat"]},
    "tigris":        {"names": ["tigris", "dicle"]},
    "rhine":         {"names": ["rhine", "rhein", "rhin", "rijn"]},
    "danube":        {"names": ["danube", "donau", "duna", "dunav", "dunarea"]},
    "colorado":      {"names": ["colorado"], "near_source": True},  # several Colorados -> proximity filter
    "columbia":      {"names": ["columbia"]},
    # delta segments carry "delta" in the name; exclude so we keep the main river
    "irrawaddy":     {"names": ["irrawaddy", "ayeyarwady"], "exclude": ["delta"]},
    "orange":        {"names": ["orange", "oranje", "gariep"]},
    "parana":        {"names": ["parana", "paraná", "rio parana"]},
    "amur":          {"names": ["amur", "heilong jiang", "heilongjiang"]},
    # match Dnieper via its alt names; never fuzzy-match the separate Dniester
    "dnieper":       {"names": ["dnieper", "dnipro", "dnepr"], "exclude": ["dniester", "dnister", "dnestr"]},
    "senegal-river": {"names": ["senegal", "sénégal"]},
    "orinoco":       {"names": ["orinoco"]},
    "sao-francisco": {"names": ["sao francisco", "são francisco", "rio sao francisco"]},
    "tocantins":     {"names": ["tocantins"]},
}


def norm(s: str | None) -> str:
    """Lowercase, strip accents/punctuation noise for tolerant name matching."""
    if not s:
        return ""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return s.strip().lower()


def fetch_layer():
    """Download+unzip the NE rivers layer into CACHE if absent; return a Reader."""
    import shapefile  # imported here so --help works without pyshp
    base = os.path.join(CACHE, os.path.basename(LAYER))
    if not os.path.exists(base + ".shp"):
        os.makedirs(CACHE, exist_ok=True)
        url = f"{NE_BASE}/{LAYER}.zip"
        print(f"  downloading {url}")
        with urllib.request.urlopen(url, timeout=180) as r:
            zipfile.ZipFile(io.BytesIO(r.read())).extractall(CACHE)
    return shapefile.Reader(base)


def record_names(rec) -> list[str]:
    """All normalized name candidates for a NE record."""
    out = []
    for field in ("name", "name_en", "name_alt"):
        try:
            val = rec[field]
        except (KeyError, IndexError):
            continue
        if not val:
            continue
        # name_alt can be a "|"-delimited list
        for piece in str(val).split("|"):
            out.append(norm(piece))
    return out


def segment_points(shape):
    """Flatten a (possibly multi-part) NE polyline shape into one ordered point list."""
    idx = list(shape.parts) + [len(shape.points)]
    pts = []
    for i in range(len(idx) - 1):
        pts.extend(shape.points[idx[i]:idx[i + 1]])
    return [(p[0], p[1]) for p in pts]


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def stitch(segments):
    """Chain segments into ordered parts by nearest-endpoint joining.

    Returns a list of parts (each a list of (lon, lat) points). Segments whose
    nearest connection to every open chain exceeds JOIN_TOLERANCE start a new part.
    """
    segs = [s for s in segments if len(s) >= 2]
    parts = []
    while segs:
        current = list(segs.pop(0))
        extended = True
        while extended:
            extended = False
            head, tail = current[0], current[-1]
            best = None  # (gap, seg_index, attach_to_tail, reverse_seg)
            for i, s in enumerate(segs):
                for attach_tail in (True, False):
                    anchor = tail if attach_tail else head
                    # joining s in either orientation
                    for rev in (False, True):
                        seg = s[::-1] if rev else s
                        gap = dist(anchor, seg[0])
                        if best is None or gap < best[0]:
                            best = (gap, i, attach_tail, rev)
            if best and best[0] <= JOIN_TOLERANCE:
                _, i, attach_tail, rev = best
                seg = segs.pop(i)
                seg = seg[::-1] if rev else seg
                if attach_tail:
                    current.extend(seg)
                else:
                    current = seg[::-1] + current
                extended = True
        parts.append(current)
    return parts


def orient(part, source, mouth):
    """Orient a part so it runs from the end nearest `source` to the end nearest `mouth`."""
    start, end = part[0], part[-1]
    # source/mouth are (lat, lon); part points are (lon, lat)
    src = (source[1], source[0])
    mth = (mouth[1], mouth[0])
    forward = dist(start, src) + dist(end, mth)
    backward = dist(end, src) + dist(start, mth)
    return part if forward <= backward else part[::-1]


def dedup_round(part):
    out = []
    for lon, lat in part:
        p = [round(lon, COORD_DECIMALS), round(lat, COORD_DECIMALS)]
        if out and dist(out[-1], p) < DEDUP_EPS:
            continue
        out.append(p)
    return out


def build_rivers():
    reader = fetch_layer()
    shapes, recs = reader.shapes(), reader.records()
    coords = {r["id"]: r for r in load_json("rivers.json")}

    # index segments: list of (normalized-names, rivernum, points)
    def rec_num(rec):
        try:
            return int(rec["rivernum"])
        except (KeyError, IndexError, TypeError, ValueError):
            return None
    indexed = [(record_names(rec), rec_num(rec), segment_points(s))
               for s, rec in zip(shapes, recs)]

    out = []
    for rid, spec in RIVER_MAP.items():
        wanted = {norm(n) for n in spec.get("names", [])}
        wanted_nums = set(spec.get("rivernums", []))
        exclude = {norm(e) for e in spec.get("exclude", [])}
        matched = []
        for names, rnum, pts in indexed:
            if len(pts) < 2:
                continue
            if exclude and any(any(ex in nm for ex in exclude) for nm in names if nm):
                continue
            if (wanted and wanted & set(names)) or (wanted_nums and rnum in wanted_nums):
                matched.append(pts)

        if spec.get("near_source") and rid in coords and matched:
            r = coords[rid]
            src = (r["sourceLon"], r["sourceLat"])
            # keep only segments within a generous radius of the stored source/mouth
            # corridor; drops same-named rivers on other continents
            mth = (r["mouthLon"], r["mouthLat"])
            def relevant(pts):
                c = pts[len(pts) // 2]
                return min(dist(c, src), dist(c, mth)) < 12.0
            matched = [m for m in matched if relevant(m)] or matched

        if not matched:
            crit = spec.get("names") or f"rivernums {spec.get('rivernums')}"
            print(f"  WARN river {rid}: no NE segments matched {crit} -> straight-line fallback")
            continue

        parts = stitch(matched)
        if rid in coords:
            r = coords[rid]
            src = (r["sourceLat"], r["sourceLon"])
            mth = (r["mouthLat"], r["mouthLon"])
            # orient the longest part by source/mouth; keep parts longest-first
            parts.sort(key=len, reverse=True)
            parts = [orient(p, src, mth) for p in parts]
        cleaned = [dedup_round(p) for p in parts]
        cleaned = [p for p in cleaned if len(p) >= 2]
        if not cleaned:
            print(f"  WARN river {rid}: matched but produced no usable path -> fallback")
            continue
        total = sum(len(p) for p in cleaned)
        out.append({"id": rid, "parts": cleaned})
        print(f"  {rid}: {len(cleaned)} part(s), {total} vertices")
    return out


def load_json(name):
    with open(os.path.join(RES, name)) as f:
        return json.load(f)


def write_json(name, data):
    path = os.path.join(RES, name)
    lines = [json.dumps(e, separators=(",", ":"), ensure_ascii=False) for e in data]
    with open(path, "w") as f:
        f.write("[\n" + ",\n".join(lines) + "\n]\n")
    total = sum(sum(len(p) for p in e["parts"]) for e in data)
    print(f"  wrote {path} ({len(data)} rivers, {total} vertices)")


def verify(name, data):
    try:
        committed = {e["id"]: e for e in load_json(name)}
    except FileNotFoundError:
        print(f"  {name}: no committed file to compare")
        return
    gen = {e["id"]: e for e in data}
    only_committed = sorted(set(committed) - set(gen))
    only_gen = sorted(set(gen) - set(committed))
    print(f"  {name}: committed={len(committed)} generated={len(gen)}")
    if only_committed:
        print(f"    only in committed: {only_committed}")
    if only_gen:
        print(f"    only in generated: {only_gen}")
    for rid in sorted(set(gen) & set(committed)):
        cg, cc = gen[rid], committed[rid]
        gv = sum(len(p) for p in cg["parts"])
        cv = sum(len(p) for p in cc["parts"])
        if gv != cv or len(cg["parts"]) != len(cc["parts"]):
            print(f"    {rid}: parts gen={len(cg['parts'])}/{gv}v committed={len(cc['parts'])}/{cv}v")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--write", action="store_true",
                    help="overwrite the committed JSON (default: verify only, write nothing)")
    args = ap.parse_args()
    print("Rivers:")
    rivers = build_rivers()
    matched_ids = {e["id"] for e in rivers}
    all_ids = {r["id"] for r in load_json("rivers.json")}
    fallback = sorted(all_ids - matched_ids)
    print(f"\nMatched {len(matched_ids)}/{len(all_ids)} rivers; "
          f"straight-line fallback for: {fallback or 'none'}")
    if args.write:
        write_json("river-paths.json", rivers)
    else:
        print("\nVerify (generated vs committed) — pass --write to overwrite:")
        verify("river-paths.json", rivers)


if __name__ == "__main__":
    sys.exit(main())
