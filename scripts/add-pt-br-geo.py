#!/usr/bin/env python3
"""One-shot helper: inject standard Brazilian Portuguese exonyms (name_pt_br / capital_pt_br) into the
source geo JSONs for story 007 (Brazilian Portuguese content).

Reads the curated id -> Brazilian Portuguese maps below and writes `name_pt_br` (all entities) and
`capital_pt_br` (countries only) into each object in countries.json / rivers.json / mountains.json /
seas.json, placed immediately after the base `name` / `capital` key so the new columns sit beside
their siblings. Idempotent: re-running overwrites the pt_br columns with the curated values. Preserves
all other keys and their order, and round-trips JSON with ensure_ascii=False + 2-space indent to match
the existing files.

The translations are standard, well-established Brazilian Portuguese (pt-BR) exonyms — NOT European
Portuguese. pt-BR uses Latin script, so many values legitimately share letters with English; that is
correct, not an untranslated stub. No blank or English-placeholder values — the strict completeness
gate fails on any missing/blank value.
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RES = REPO_ROOT / "Hanahuac" / "Resources"

# id -> (name_pt_br, capital_pt_br)
COUNTRIES: dict[str, tuple[str, str]] = {
    "DZ": ("Argélia", "Argel"),
    "AO": ("Angola", "Luanda"),
    "BJ": ("Benim", "Porto-Novo"),
    "BW": ("Botsuana", "Gaborone"),
    "BF": ("Burquina Faso", "Uagadugu"),
    "BI": ("Burundi", "Gitega"),
    "CV": ("Cabo Verde", "Praia"),
    "CM": ("Camarões", "Iaundé"),
    "CF": ("República Centro-Africana", "Bangui"),
    "TD": ("Chade", "Jamena"),
    "KM": ("Comores", "Moroni"),
    "CD": ("República Democrática do Congo", "Quinxasa"),
    "DJ": ("Djibuti", "Djibuti"),
    "EG": ("Egito", "Cairo"),
    "GQ": ("Guiné Equatorial", "Malabo"),
    "ER": ("Eritreia", "Asmara"),
    "SZ": ("Essuatíni", "Mbabane"),
    "ET": ("Etiópia", "Adis Abeba"),
    "GA": ("Gabão", "Libreville"),
    "GM": ("Gâmbia", "Banjul"),
    "GH": ("Gana", "Acra"),
    "GN": ("Guiné", "Conacri"),
    "GW": ("Guiné-Bissau", "Bissau"),
    "CI": ("Costa do Marfim", "Iamussucro"),
    "KE": ("Quênia", "Nairóbi"),
    "LS": ("Lesoto", "Maseru"),
    "LR": ("Libéria", "Monróvia"),
    "LY": ("Líbia", "Trípoli"),
    "MG": ("Madagascar", "Antananarivo"),
    "MW": ("Maláui", "Lilôngue"),
    "ML": ("Mali", "Bamako"),
    "MR": ("Mauritânia", "Nuaquchote"),
    "MU": ("Maurício", "Port Louis"),
    "MA": ("Marrocos", "Rabat"),
    "MZ": ("Moçambique", "Maputo"),
    "NA": ("Namíbia", "Windhoek"),
    "NE": ("Níger", "Niamei"),
    "NG": ("Nigéria", "Abuja"),
    "CG": ("República do Congo", "Brazzaville"),
    "RW": ("Ruanda", "Kigali"),
    "ST": ("São Tomé e Príncipe", "São Tomé"),
    "SN": ("Senegal", "Dacar"),
    "SC": ("Seicheles", "Victoria"),
    "SL": ("Serra Leoa", "Freetown"),
    "SO": ("Somália", "Mogadíscio"),
    "ZA": ("África do Sul", "Pretória"),
    "SS": ("Sudão do Sul", "Juba"),
    "SD": ("Sudão", "Cartum"),
    "TZ": ("Tanzânia", "Dodoma"),
    "TG": ("Togo", "Lomé"),
    "TN": ("Tunísia", "Túnis"),
    "UG": ("Uganda", "Campala"),
    "ZM": ("Zâmbia", "Lusaca"),
    "ZW": ("Zimbábue", "Harare"),
    "AF": ("Afeganistão", "Cabul"),
    "AM": ("Armênia", "Yerevan"),
    "AZ": ("Azerbaijão", "Baku"),
    "BH": ("Bahrein", "Manama"),
    "BD": ("Bangladesh", "Daca"),
    "BT": ("Butão", "Timbu"),
    "BN": ("Brunei", "Bandar Seri Begauan"),
    "KH": ("Camboja", "Phnom Penh"),
    "CN": ("China", "Pequim"),
    "CY": ("Chipre", "Nicósia"),
    "GE": ("Geórgia", "Tbilisi"),
    "IN": ("Índia", "Nova Délhi"),
    "ID": ("Indonésia", "Jacarta"),
    "IR": ("Irã", "Teerã"),
    "IQ": ("Iraque", "Bagdá"),
    "IL": ("Israel", "Jerusalém"),
    "JP": ("Japão", "Tóquio"),
    "JO": ("Jordânia", "Amã"),
    "KZ": ("Cazaquistão", "Astana"),
    "KW": ("Kuwait", "Cidade do Kuwait"),
    "KG": ("Quirguistão", "Bishkek"),
    "LA": ("Laos", "Vienciana"),
    "LB": ("Líbano", "Beirute"),
    "MY": ("Malásia", "Kuala Lumpur"),
    "MV": ("Maldivas", "Malé"),
    "MN": ("Mongólia", "Ulan Bator"),
    "MM": ("Mianmar", "Naypyidaw"),
    "NP": ("Nepal", "Catmandu"),
    "KP": ("Coreia do Norte", "Pyongyang"),
    "OM": ("Omã", "Mascate"),
    "PK": ("Paquistão", "Islamabade"),
    "PH": ("Filipinas", "Manila"),
    "PS": ("Palestina", "Ramala"),
    "QA": ("Catar", "Doha"),
    "SA": ("Arábia Saudita", "Riade"),
    "SG": ("Singapura", "Singapura"),
    "KR": ("Coreia do Sul", "Seul"),
    "LK": ("Sri Lanka", "Sri Jayawardenapura Kotte"),
    "SY": ("Síria", "Damasco"),
    "TW": ("Taiwan", "Taipé"),
    "TJ": ("Tajiquistão", "Duchambé"),
    "TH": ("Tailândia", "Bangcoc"),
    "TL": ("Timor-Leste", "Díli"),
    "TR": ("Turquia", "Ancara"),
    "TM": ("Turcomenistão", "Asgabate"),
    "AE": ("Emirados Árabes Unidos", "Abu Dhabi"),
    "UZ": ("Uzbequistão", "Tashkent"),
    "VN": ("Vietnã", "Hanói"),
    "YE": ("Iêmen", "Sanaa"),
    "AL": ("Albânia", "Tirana"),
    "AD": ("Andorra", "Andorra-a-Velha"),
    "AT": ("Áustria", "Viena"),
    "BY": ("Belarus", "Minsk"),
    "BE": ("Bélgica", "Bruxelas"),
    "BA": ("Bósnia e Herzegovina", "Sarajevo"),
    "BG": ("Bulgária", "Sófia"),
    "HR": ("Croácia", "Zagreb"),
    "CZ": ("Tchéquia", "Praga"),
    "DK": ("Dinamarca", "Copenhague"),
    "EE": ("Estônia", "Talim"),
    "FI": ("Finlândia", "Helsinque"),
    "FR": ("França", "Paris"),
    "DE": ("Alemanha", "Berlim"),
    "GR": ("Grécia", "Atenas"),
    "HU": ("Hungria", "Budapeste"),
    "IS": ("Islândia", "Reykjavik"),
    "IE": ("Irlanda", "Dublin"),
    "IT": ("Itália", "Roma"),
    "XK": ("Kosovo", "Pristina"),
    "LV": ("Letônia", "Riga"),
    "LI": ("Liechtenstein", "Vaduz"),
    "LT": ("Lituânia", "Vilnius"),
    "LU": ("Luxemburgo", "Luxemburgo"),
    "MT": ("Malta", "Valeta"),
    "MD": ("Moldávia", "Chișinău"),
    "MC": ("Mônaco", "Mônaco"),
    "ME": ("Montenegro", "Podgorica"),
    "NL": ("Países Baixos", "Amsterdã"),
    "MK": ("Macedônia do Norte", "Skopje"),
    "NO": ("Noruega", "Oslo"),
    "PL": ("Polônia", "Varsóvia"),
    "PT": ("Portugal", "Lisboa"),
    "RO": ("Romênia", "Bucareste"),
    "RU": ("Rússia", "Moscou"),
    "SM": ("San Marino", "San Marino"),
    "RS": ("Sérvia", "Belgrado"),
    "SK": ("Eslováquia", "Bratislava"),
    "SI": ("Eslovênia", "Liubliana"),
    "ES": ("Espanha", "Madri"),
    "SE": ("Suécia", "Estocolmo"),
    "CH": ("Suíça", "Berna"),
    "UA": ("Ucrânia", "Kiev"),
    "GB": ("Reino Unido", "Londres"),
    "VA": ("Cidade do Vaticano", "Cidade do Vaticano"),
    "AG": ("Antígua e Barbuda", "Saint John's"),
    "BS": ("Bahamas", "Nassau"),
    "BB": ("Barbados", "Bridgetown"),
    "BZ": ("Belize", "Belmopan"),
    "CA": ("Canadá", "Ottawa"),
    "CR": ("Costa Rica", "San José"),
    "CU": ("Cuba", "Havana"),
    "DM": ("Dominica", "Roseau"),
    "DO": ("República Dominicana", "Santo Domingo"),
    "SV": ("El Salvador", "San Salvador"),
    "GD": ("Granada", "Saint George's"),
    "GT": ("Guatemala", "Cidade da Guatemala"),
    "HT": ("Haiti", "Porto Príncipe"),
    "HN": ("Honduras", "Tegucigalpa"),
    "JM": ("Jamaica", "Kingston"),
    "MX": ("México", "Cidade do México"),
    "NI": ("Nicarágua", "Manágua"),
    "PA": ("Panamá", "Cidade do Panamá"),
    "KN": ("São Cristóvão e Névis", "Basseterre"),
    "LC": ("Santa Lúcia", "Castries"),
    "VC": ("São Vicente e Granadinas", "Kingstown"),
    "TT": ("Trinidad e Tobago", "Porto de Espanha"),
    "US": ("Estados Unidos", "Washington, D.C."),
    "AU": ("Austrália", "Camberra"),
    "FJ": ("Fiji", "Suva"),
    "KI": ("Quiribati", "Tarawa do Sul"),
    "MH": ("Ilhas Marshall", "Majuro"),
    "FM": ("Micronésia", "Palikir"),
    "NR": ("Nauru", "Yaren"),
    "NZ": ("Nova Zelândia", "Wellington"),
    "PW": ("Palau", "Ngerulmud"),
    "PG": ("Papua-Nova Guiné", "Port Moresby"),
    "WS": ("Samoa", "Apia"),
    "SB": ("Ilhas Salomão", "Honiara"),
    "TO": ("Tonga", "Nucualofa"),
    "TV": ("Tuvalu", "Funafuti"),
    "VU": ("Vanuatu", "Port Vila"),
    "AR": ("Argentina", "Buenos Aires"),
    "BO": ("Bolívia", "Sucre"),
    "BR": ("Brasil", "Brasília"),
    "CL": ("Chile", "Santiago"),
    "CO": ("Colômbia", "Bogotá"),
    "EC": ("Equador", "Quito"),
    "GY": ("Guiana", "Georgetown"),
    "PY": ("Paraguai", "Assunção"),
    "PE": ("Peru", "Lima"),
    "SR": ("Suriname", "Paramaribo"),
    "UY": ("Uruguai", "Montevidéu"),
    "VE": ("Venezuela", "Caracas"),
}

RIVERS: dict[str, str] = {
    "nile": "Rio Nilo",
    "amazon": "Rio Amazonas",
    "yangtze": "Rio Yangtzé",
    "mississippi": "Rio Mississippi",
    "yenisei": "Rio Ienissei",
    "yellow-river": "Rio Amarelo",
    "ob": "Rio Ob",
    "congo": "Rio Congo",
    "lena": "Rio Lena",
    "niger": "Rio Níger",
    "mekong": "Rio Mecongue",
    "missouri": "Rio Missouri",
    "volga": "Rio Volga",
    "zambezi": "Rio Zambeze",
    "ganges": "Rio Ganges",
    "indus": "Rio Indo",
    "murray": "Rio Murray",
    "euphrates": "Rio Eufrates",
    "tigris": "Rio Tigre",
    "rhine": "Rio Reno",
    "danube": "Rio Danúbio",
    "colorado": "Rio Colorado",
    "columbia": "Rio Columbia",
    "irrawaddy": "Rio Irauádi",
    "orange": "Rio Laranja",
    "parana": "Rio Paraná",
    "amur": "Rio Amur",
    "dnieper": "Rio Dniepre",
    "senegal-river": "Rio Senegal",
    "orinoco": "Rio Orinoco",
    "sao-francisco": "Rio São Francisco",
    "tocantins": "Rio Tocantins",
}

MOUNTAINS: dict[str, str] = {
    "himalayas": "Himalaia",
    "andes": "Cordilheira dos Andes",
    "rockies": "Montanhas Rochosas",
    "alps": "Alpes",
    "great-dividing-range": "Grande Cordilheira Divisória",
    "kunlun": "Montanhas Kunlun",
    "tian-shan": "Tian Shan",
    "altai": "Montanhas Altai",
    "caucasus": "Cáucaso",
    "pyrenees": "Pirenéus",
    "carpathians": "Cárpatos",
    "appalachians": "Montes Apalaches",
    "atlas": "Cordilheira do Atlas",
    "drakensberg": "Montanhas Drakensberg",
    "ethiopian-highlands": "Planalto Etíope",
    "scandinavian-mountains": "Montanhas Escandinavas",
    "hindu-kush": "Hindu Kush",
    "karakoram": "Caracórum",
    "pamir": "Montanhas Pamir",
    "sierra-nevada-us": "Serra Nevada",
    "southern-alps": "Alpes do Sul",
    "zagros": "Montes Zagros",
    "eastern-rift-highlands": "Planaltos do Vale do Rift Oriental",
}

SEAS: dict[str, str] = {
    "pacific": "Oceano Pacífico",
    "atlantic": "Oceano Atlântico",
    "indian": "Oceano Índico",
    "southern": "Oceano Antártico",
    "arctic": "Oceano Ártico",
    "mediterranean": "Mar Mediterrâneo",
    "caribbean": "Mar do Caribe",
    "south-china": "Mar da China Meridional",
    "bering": "Mar de Bering",
    "gulf-of-mexico": "Golfo do México",
    "north-sea": "Mar do Norte",
    "red-sea": "Mar Vermelho",
    "black-sea": "Mar Negro",
    "caspian-sea": "Mar Cáspio",
    "persian-gulf": "Golfo Pérsico",
    "east-china": "Mar da China Oriental",
    "bay-of-bengal": "Baía de Bengala",
    "arabian-sea": "Mar da Arábia",
    "coral-sea": "Mar de Coral",
    "tasman-sea": "Mar da Tasmânia",
}


def insert_after(obj: dict, anchor: str, key: str, value: str) -> dict:
    """Return a new dict with (key, value) inserted immediately after `anchor`, preserving order.

    If `key` already exists it is removed first and re-inserted at the anchor position so the column
    sits beside its base sibling. If `anchor` is absent, the key is appended at the end.
    """
    out: dict = {}
    for existing_key, existing_value in obj.items():
        if existing_key == key:
            continue  # drop any prior copy; re-added at the anchor
        out[existing_key] = existing_value
        if existing_key == anchor:
            out[key] = value
    if anchor not in obj:
        out[key] = value
    return out


def process(filename: str, names: dict, has_capital: bool) -> None:
    path = RES / filename
    data = json.loads(path.read_text(encoding="utf-8"))
    missing = [o["id"] for o in data if o["id"] not in names]
    if missing:
        raise SystemExit(f"{filename}: no Brazilian Portuguese mapping for ids: {missing}")
    new_data = []
    for obj in data:
        oid = obj["id"]
        entry = names[oid]
        name_pt_br = entry[0] if has_capital else entry
        obj = insert_after(obj, "name", "name_pt_br", name_pt_br)
        if has_capital:
            obj = insert_after(obj, "capital", "capital_pt_br", entry[1])
        new_data.append(obj)
    path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"{filename}: wrote name_pt_br for {len(new_data)} entities"
        + (" + capital_pt_br" if has_capital else "")
    )


def main() -> None:
    process("countries.json", COUNTRIES, has_capital=True)
    process("rivers.json", RIVERS, has_capital=False)
    process("mountains.json", MOUNTAINS, has_capital=False)
    process("seas.json", SEAS, has_capital=False)


if __name__ == "__main__":
    main()
