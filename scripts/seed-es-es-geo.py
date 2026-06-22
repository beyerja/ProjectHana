#!/usr/bin/env python3
"""One-off: seed Castilian (Peninsular) Spanish geo columns into the bundled geo JSON.

Adds ``name_es_es`` (and ``capital_es_es`` for countries) to EVERY entity in
``countries.json``/``rivers.json``/``mountains.json``/``seas.json``.

The existing Mexican-Spanish columns (``name_es``/``capital_es``) already use RAE-standard
exonyms that are, for the overwhelming majority of these geographic entries, identical to
Peninsular usage. So the Castilian column is seeded from the es-MX value, and only the genuine
Peninsular divergences are overridden via the COUNTRY_NAME_OVERRIDES / COUNTRY_CAPITAL_OVERRIDES
maps below (we do NOT diverge artificially — completeness with correct Spanish is the goal).

Idempotent: re-running rewrites the es_es columns from the same source + overrides. The es_es
key is inserted immediately after the es key so the JSON stays readable.

Usage:
    python3 scripts/seed-es-es-geo.py
"""

from __future__ import annotations

import json
from collections import OrderedDict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RESOURCES = REPO_ROOT / "Hanahuac" / "Resources"

# Genuine Peninsular (Spain) divergences from the es-MX exonyms. Keyed by country id.
# Spain's RAE/Fundéu-preferred form differs from the Latin-American form used in name_es.
COUNTRY_NAME_OVERRIDES = {
    "SA": "Arabia Saudí",  # LatAm "Arabia Saudita" -> Spain "Arabia Saudí"
}

# Country capitals: the es-MX capital column already matches Peninsular usage for every entry,
# so no capital override is currently needed. Kept for future curation.
COUNTRY_CAPITAL_OVERRIDES: dict[str, str] = {}

# Rivers / mountains / seas: the es-MX names match Peninsular usage; no overrides needed.
RIVER_NAME_OVERRIDES: dict[str, str] = {}
MOUNTAIN_NAME_OVERRIDES: dict[str, str] = {}
SEA_NAME_OVERRIDES: dict[str, str] = {}


def _insert_after(obj: dict, anchor: str, key: str, value) -> OrderedDict:
    """Return an OrderedDict copy of obj with key/value inserted right after anchor."""
    out: OrderedDict = OrderedDict()
    for k, v in obj.items():
        if k == key:
            continue  # drop any pre-existing es_es so we re-seed cleanly
        out[k] = v
        if k == anchor:
            out[key] = value
    if anchor not in obj:  # anchor missing: append at end
        out[key] = value
    return out


def _seed(filename: str, name_overrides: dict, capital_overrides: dict | None) -> None:
    path = RESOURCES / filename
    data = json.loads(path.read_text(encoding="utf-8"))
    seeded = []
    for entry in data:
        eid = entry["id"]
        name_es = entry.get("name_es")
        name_value = name_overrides.get(eid, name_es)
        new_entry = _insert_after(entry, "name_es", "name_es_es", name_value)
        if capital_overrides is not None:
            capital_es = new_entry.get("capital_es")
            capital_value = capital_overrides.get(eid, capital_es)
            new_entry = _insert_after(new_entry, "capital_es", "capital_es_es", capital_value)
        seeded.append(new_entry)
    path.write_text(json.dumps(seeded, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"seeded es_es into {filename} ({len(seeded)} entries)")


def main() -> None:
    _seed("countries.json", COUNTRY_NAME_OVERRIDES, COUNTRY_CAPITAL_OVERRIDES)
    _seed("rivers.json", RIVER_NAME_OVERRIDES, None)
    _seed("mountains.json", MOUNTAIN_NAME_OVERRIDES, None)
    _seed("seas.json", SEA_NAME_OVERRIDES, None)


if __name__ == "__main__":
    main()
