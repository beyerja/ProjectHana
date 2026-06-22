#!/usr/bin/env python3
"""Generate per-language geo-name ODR pack JSON from the bundled geo source data.

For each downloadable (non-base) language — fr, de, es-ES, ca, eu, ko, nah — this emits a
``Hanahuac/Resources/<code>-geo.json`` file in the ``GeoNamePackData`` schema
(see ``Hanahuac/L10n/Packs/GeoNamePackData.swift``):

    {
      "version": 1,
      "code": "fr",
      "entries": {
        "<geoId>": { "name": "...", "capital": "..." },
        ...
      }
    }

The source of truth is the bundled geo JSON (``countries.json``/``rivers.json``/
``mountains.json``/``seas.json``). Only the per-language translation columns become
pack entries; the English base name stays on the geo model and is the resolver's
final fallback, so it is never written into a pack. An entry is emitted only when the
language actually has a name or capital for it.

These packs are DATA-ONLY: pure JSON, no executable content. They are tagged as
On-Demand Resources (``lang-<code>``) in ``project.yml`` so the non-base geo names
ship on demand rather than in the always-bundled binary. Built per app version from
the in-tree source data; there is no out-of-band / OTA update path.

The base languages en and es-MX are intentionally NOT generated: en is the bundled
base (resolver fallback) and es-MX ships always-bundled with its ``.lproj``.

Usage:
    python3 scripts/generate-geo-packs.py            # write the pack files
    python3 scripts/generate-geo-packs.py --check     # verify committed packs are up to date
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Schema version emitted, kept in sync with GeoNamePackData.currentVersion.
PACK_VERSION = 1

# Downloadable (non-base) languages that get an ODR geo pack. es-MX is a bundled base
# language and en is the resolver fallback, so neither gets a generated pack.
PACK_LANGUAGES = ["fr", "de", "es-ES", "ca", "eu", "ko", "nah"]

# Map an AppLocale code to the JSON field suffix used in the bundled source data.
SUFFIX_BY_CODE = {
    "fr": "fr",
    "de": "de",
    "es-ES": "es_es",
    "ca": "ca",
    "eu": "eu",
    "ko": "ko",
    "nah": "nah",
}

REPO_ROOT = Path(__file__).resolve().parent.parent
RESOURCES = REPO_ROOT / "Hanahuac" / "Resources"


def _load(name: str) -> list[dict]:
    with (RESOURCES / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def _nonempty(value) -> str | None:
    if isinstance(value, str) and value.strip():
        return value
    return None


def build_pack(code: str) -> dict:
    """Build one language's GeoNamePackData dict from the bundled geo source data."""
    suffix = SUFFIX_BY_CODE[code]
    name_key = f"name_{suffix}"
    capital_key = f"capital_{suffix}"
    entries: dict[str, dict] = {}

    # Countries carry both a name and a capital.
    for country in _load("countries.json"):
        name = _nonempty(country.get(name_key))
        capital = _nonempty(country.get(capital_key))
        if name is None and capital is None:
            continue
        entry: dict[str, str] = {}
        if name is not None:
            entry["name"] = name
        if capital is not None:
            entry["capital"] = capital
        entries[country["id"]] = entry

    # Rivers, mountains, seas carry a name only.
    for source in ("rivers.json", "mountains.json", "seas.json"):
        for item in _load(source):
            name = _nonempty(item.get(name_key))
            if name is None:
                continue
            entries[item["id"]] = {"name": name}

    return {"version": PACK_VERSION, "code": code, "entries": entries}


def render(pack: dict) -> str:
    """Stable, sorted JSON text so regeneration produces a deterministic diff."""
    ordered = {
        "version": pack["version"],
        "code": pack["code"],
        "entries": {geo_id: pack["entries"][geo_id] for geo_id in sorted(pack["entries"])},
    }
    return json.dumps(ordered, ensure_ascii=False, indent=2, sort_keys=False) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify committed pack files match freshly generated output (no writes)",
    )
    args = parser.parse_args()

    stale: list[str] = []
    for code in PACK_LANGUAGES:
        pack = build_pack(code)
        text = render(pack)
        out = RESOURCES / f"{code}-geo.json"
        if args.check:
            current = out.read_text(encoding="utf-8") if out.exists() else None
            if current != text:
                stale.append(str(out.relative_to(REPO_ROOT)))
            continue
        out.write_text(text, encoding="utf-8")
        print(f"wrote {out.relative_to(REPO_ROOT)} ({len(pack['entries'])} entries)")

    if args.check:
        if stale:
            print("Geo packs are out of date; run `just geo-packs`:", file=sys.stderr)
            for path in stale:
                print(f"  {path}", file=sys.stderr)
            return 1
        print("geo packs: up to date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
