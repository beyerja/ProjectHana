#!/usr/bin/env python3
"""One-shot helper: inject curated Basque (Euskara) geo columns into the bundled source data.

Adds ``name_eu`` (+ ``capital_eu`` for countries) to ``countries.json`` / ``rivers.json`` /
``mountains.json`` / ``seas.json``, placed immediately after the matching ``*_ca`` column so the
column ordering mirrors how Catalan was added. Only confident, professional Basque endonyms/exonyms
are provided; genuine gaps are deliberately omitted so they fall back through es-ES -> en (the
fallback policy permits this for `eu`).

This is committed (per CLAUDE.md: one committed script over many inline one-offs) and idempotent:
re-running overwrites the eu columns from the curated maps below and re-orders them after *_ca.

Usage:
    python3 scripts/add-eu-geo.py
"""

from __future__ import annotations

import json
from collections import OrderedDict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RESOURCES = REPO_ROOT / "Hanahuac" / "Resources"

# Curated Basque country names (exonyms/endonyms). Omitted ids fall back through es-ES.
COUNTRY_NAME_EU: dict[str, str] = {
    "DZ": "Aljeria",
    "AO": "Angola",
    "BJ": "Benin",
    "BW": "Botswana",
    "BF": "Burkina Faso",
    "BI": "Burundi",
    "CV": "Cabo Verde",
    "CM": "Kamerun",
    "CF": "Afrika Erdiko Errepublika",
    "TD": "Txad",
    "KM": "Komoreak",
    "CD": "Kongoko Errepublika Demokratikoa",
    "DJ": "Djibuti",
    "EG": "Egipto",
    "GQ": "Ekuatore Ginea",
    "ER": "Eritrea",
    "SZ": "Eswatini",
    "ET": "Etiopia",
    "GA": "Gabon",
    "GM": "Gambia",
    "GH": "Ghana",
    "GN": "Ginea",
    "GW": "Ginea Bissau",
    "CI": "Boli Kosta",
    "KE": "Kenya",
    "LS": "Lesotho",
    "LR": "Liberia",
    "LY": "Libia",
    "MG": "Madagaskar",
    "MW": "Malawi",
    "ML": "Mali",
    "MR": "Mauritania",
    "MU": "Maurizio",
    "MA": "Maroko",
    "MZ": "Mozambike",
    "NA": "Namibia",
    "NE": "Niger",
    "NG": "Nigeria",
    "CG": "Kongoko Errepublika",
    "RW": "Ruanda",
    "ST": "Sao Tome eta Principe",
    "SN": "Senegal",
    "SC": "Seychelleak",
    "SL": "Sierra Leona",
    "SO": "Somalia",
    "ZA": "Hegoafrika",
    "SS": "Hego Sudan",
    "SD": "Sudan",
    "TZ": "Tanzania",
    "TG": "Togo",
    "TN": "Tunisia",
    "UG": "Uganda",
    "ZM": "Zambia",
    "ZW": "Zimbabwe",
    "AF": "Afganistan",
    "AM": "Armenia",
    "AZ": "Azerbaijan",
    "BH": "Bahrain",
    "BD": "Bangladesh",
    "BT": "Bhutan",
    "BN": "Brunei",
    "KH": "Kanbodia",
    "CN": "Txina",
    "CY": "Zipre",
    "GE": "Georgia",
    "IN": "India",
    "ID": "Indonesia",
    "IR": "Iran",
    "IQ": "Irak",
    "IL": "Israel",
    "JP": "Japonia",
    "JO": "Jordania",
    "KZ": "Kazakhstan",
    "KW": "Kuwait",
    "KG": "Kirgizistan",
    "LA": "Laos",
    "LB": "Libano",
    "MY": "Malaysia",
    "MV": "Maldivak",
    "MN": "Mongolia",
    "MM": "Myanmar",
    "NP": "Nepal",
    "KP": "Ipar Korea",
    "OM": "Oman",
    "PK": "Pakistan",
    "PH": "Filipinak",
    "PS": "Palestina",
    "QA": "Qatar",
    "SA": "Saudi Arabia",
    "SG": "Singapur",
    "KR": "Hego Korea",
    "LK": "Sri Lanka",
    "SY": "Siria",
    "TW": "Taiwan",
    "TJ": "Tajikistan",
    "TH": "Thailandia",
    "TL": "Ekialdeko Timor",
    "TR": "Turkia",
    "TM": "Turkmenistan",
    "AE": "Arabiar Emirerri Batuak",
    "UZ": "Uzbekistan",
    "VN": "Vietnam",
    "YE": "Yemen",
    "AL": "Albania",
    "AD": "Andorra",
    "AT": "Austria",
    "BY": "Bielorrusia",
    "BE": "Belgika",
    "BA": "Bosnia-Herzegovina",
    "BG": "Bulgaria",
    "HR": "Kroazia",
    "CZ": "Txekia",
    "DK": "Danimarka",
    "EE": "Estonia",
    "FI": "Finlandia",
    "FR": "Frantzia",
    "DE": "Alemania",
    "GR": "Grezia",
    "HU": "Hungaria",
    "IS": "Islandia",
    "IE": "Irlanda",
    "IT": "Italia",
    "XK": "Kosovo",
    "LV": "Letonia",
    "LI": "Liechtenstein",
    "LT": "Lituania",
    "LU": "Luxenburgo",
    "MT": "Malta",
    "MD": "Moldavia",
    "MC": "Monako",
    "ME": "Montenegro",
    "NL": "Herbehereak",
    "MK": "Ipar Mazedonia",
    "NO": "Norvegia",
    "PL": "Polonia",
    "PT": "Portugal",
    "RO": "Errumania",
    "RU": "Errusia",
    "SM": "San Marino",
    "RS": "Serbia",
    "SK": "Eslovakia",
    "SI": "Eslovenia",
    "ES": "Espainia",
    "SE": "Suedia",
    "CH": "Suitza",
    "UA": "Ukraina",
    "GB": "Erresuma Batua",
    "VA": "Vatikano Hiria",
    "AG": "Antigua eta Barbuda",
    "BS": "Bahamak",
    "BB": "Barbados",
    "BZ": "Belize",
    "CA": "Kanada",
    "CR": "Costa Rica",
    "CU": "Kuba",
    "DM": "Dominika",
    "DO": "Dominikar Errepublika",
    "SV": "El Salvador",
    "GD": "Grenada",
    "GT": "Guatemala",
    "HT": "Haiti",
    "HN": "Honduras",
    "JM": "Jamaika",
    "MX": "Mexiko",
    "NI": "Nikaragua",
    "PA": "Panama",
    "KN": "Saint Kitts eta Nevis",
    "LC": "Santa Luzia",
    "VC": "Saint Vincent eta Grenadinak",
    "TT": "Trinidad eta Tobago",
    "US": "Ameriketako Estatu Batuak",
    "AU": "Australia",
    "FJ": "Fiji",
    "KI": "Kiribati",
    "MH": "Marshall Uharteak",
    "FM": "Mikronesia",
    "NR": "Nauru",
    "NZ": "Zeelanda Berria",
    "PW": "Palau",
    "PG": "Papua Ginea Berria",
    "WS": "Samoa",
    "SB": "Salomon Uharteak",
    "TO": "Tonga",
    "TV": "Tuvalu",
    "VU": "Vanuatu",
    "AR": "Argentina",
    "BO": "Bolivia",
    "BR": "Brasil",
    "CL": "Txile",
    "CO": "Kolonbia",
    "EC": "Ekuador",
    "GY": "Guyana",
    "PY": "Paraguai",
    "PE": "Peru",
    "SR": "Surinam",
    "UY": "Uruguai",
    "VE": "Venezuela",
}

# Curated Basque capital names. Omitted ids fall back through es-ES.
COUNTRY_CAPITAL_EU: dict[str, str] = {
    "EG": "Kairo",
    "ET": "Addis Abeba",
    "MA": "Rabat",
    "ZA": "Pretoria",
    "CD": "Kinshasa",
    "AF": "Kabul",
    "CN": "Pekin",
    "IN": "New Delhi",
    "IR": "Teheran",
    "IQ": "Bagdad",
    "IL": "Jerusalem",
    "JP": "Tokio",
    "KP": "Pyongyang",
    "KR": "Seul",
    "SY": "Damasko",
    "TR": "Ankara",
    "SA": "Riad",
    "TH": "Bangkok",
    "VN": "Hanoi",
    "AT": "Viena",
    "BE": "Brusela",
    "HR": "Zagreb",
    "CZ": "Praga",
    "DK": "Kopenhage",
    "FI": "Helsinki",
    "FR": "Paris",
    "DE": "Berlin",
    "GR": "Atenas",
    "HU": "Budapest",
    "IE": "Dublin",
    "IT": "Erroma",
    "NL": "Amsterdam",
    "NO": "Oslo",
    "PL": "Varsovia",
    "PT": "Lisboa",
    "RO": "Bukarest",
    "RU": "Mosku",
    "RS": "Belgrad",
    "ES": "Madril",
    "SE": "Stockholm",
    "CH": "Berna",
    "UA": "Kiev",
    "GB": "Londres",
    "VA": "Vatikano Hiria",
    "CA": "Ottawa",
    "CU": "Habana",
    "MX": "Mexiko Hiria",
    "US": "Washington",
    "AR": "Buenos Aires",
    "BR": "Brasilia",
    "CL": "Santiago",
    "CO": "Bogota",
    "PE": "Lima",
    "AU": "Canberra",
    "NZ": "Wellington",
}

RIVER_NAME_EU: dict[str, str] = {
    "nile": "Nilo",
    "amazon": "Amazonas",
    "yangtze": "Yangtze",
    "mississippi": "Mississippi",
    "yellow-river": "Ibai Horia",
    "congo": "Kongo",
    "niger": "Niger",
    "mekong": "Mekong",
    "volga": "Volga",
    "ganges": "Ganges",
    "indus": "Indo",
    "euphrates": "Eufrates",
    "tigris": "Tigris",
    "rhine": "Rhin",
    "danube": "Danubio",
    "colorado": "Colorado",
    "parana": "Parana",
    "amur": "Amur",
    "dnieper": "Dnieper",
    "senegal-river": "Senegal",
    "orinoco": "Orinoco",
    "sao-francisco": "São Francisco",
}

MOUNTAIN_NAME_EU: dict[str, str] = {
    "himalayas": "Himalaia",
    "andes": "Andeak",
    "rockies": "Harkaitz Mendiak",
    "alps": "Alpeak",
    "caucasus": "Kaukaso",
    "pyrenees": "Pirinioak",
    "carpathians": "Karpatoak",
    "appalachians": "Apalatxeak",
    "atlas": "Atlas mendikatea",
    "scandinavian-mountains": "Mendi Eskandinaviarrak",
    "hindu-kush": "Hindu Kush",
    "karakoram": "Karakorum",
    "sierra-nevada-us": "Sierra Nevada",
    "zagros": "Zagros mendiak",
}

SEA_NAME_EU: dict[str, str] = {
    "pacific": "Ozeano Barea",
    "atlantic": "Ozeano Atlantikoa",
    "indian": "Indiako Ozeanoa",
    "southern": "Hego Ozeanoa",
    "arctic": "Ozeano Artikoa",
    "mediterranean": "Mediterraneo itsasoa",
    "caribbean": "Karibe itsasoa",
    "south-china": "Hego Txinako itsasoa",
    "bering": "Beringeko itsasoa",
    "gulf-of-mexico": "Mexikoko Golkoa",
    "north-sea": "Ipar itsasoa",
    "red-sea": "Itsaso Gorria",
    "black-sea": "Itsaso Beltza",
    "caspian-sea": "Kaspiar itsasoa",
    "persian-gulf": "Persiar Golkoa",
    "east-china": "Ekialdeko Txinako itsasoa",
    "bay-of-bengal": "Bengalako Golkoa",
    "arabian-sea": "Arabiar itsasoa",
}


def _reorder_after(entry: dict, anchor: str, new_key: str, value: str) -> dict:
    """Return an ordered dict with ``new_key`` placed immediately after ``anchor`` (if present)."""
    out: OrderedDict[str, object] = OrderedDict()
    for key, val in entry.items():
        if key == new_key:
            continue
        out[key] = val
        if key == anchor:
            out[new_key] = value
    if anchor not in entry:
        out[new_key] = value
    return dict(out)


def _apply(file: str, name_map: dict[str, str], capital_map: dict[str, str] | None) -> None:
    path = RESOURCES / file
    raw = json.loads(path.read_text(encoding="utf-8"))
    out = []
    for entry in raw:
        gid = entry["id"]
        if gid in name_map:
            entry = _reorder_after(entry, "name_ca", "name_eu", name_map[gid])
        if capital_map is not None and gid in capital_map:
            entry = _reorder_after(entry, "capital_ca", "capital_eu", capital_map[gid])
        out.append(entry)
    path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"updated {file}: {sum(1 for e in out if 'name_eu' in e)} name_eu entries")


def main() -> None:
    _apply("countries.json", COUNTRY_NAME_EU, COUNTRY_CAPITAL_EU)
    _apply("rivers.json", RIVER_NAME_EU, None)
    _apply("mountains.json", MOUNTAIN_NAME_EU, None)
    _apply("seas.json", SEA_NAME_EU, None)


if __name__ == "__main__":
    main()
