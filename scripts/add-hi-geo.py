#!/usr/bin/env python3
"""One-shot helper: inject standard Hindi (Devanagari) exonyms (name_hi / capital_hi) into the source
geo JSONs for story 005 (Hindi content).

Reads the curated id -> Hindi maps below and writes `name_hi` (all entities) and `capital_hi`
(countries only) into each object in countries.json / rivers.json / mountains.json / seas.json,
placed immediately after the base `name` / `capital` key so the new columns sit beside their
siblings. Idempotent: re-running overwrites the hi columns with the curated values. Preserves all
other keys and their order, and round-trips JSON with ensure_ascii=False + 2-space indent to match
the existing files.

The translations are standard, well-established Hindi exonyms in Devanagari script (हिन्दी). No
blank or English-placeholder values — the strict completeness gate fails on any missing/blank value.
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RES = REPO_ROOT / "Hanahuac" / "Resources"

# id -> (name_hi, capital_hi)
COUNTRIES: dict[str, tuple[str, str]] = {
    "DZ": ("अल्जीरिया", "अल्जीयर्स"),
    "AO": ("अंगोला", "लुआंडा"),
    "BJ": ("बेनिन", "पोर्टो-नोवो"),
    "BW": ("बोत्सवाना", "गाबोरोन"),
    "BF": ("बुर्किना फासो", "औगादुगू"),
    "BI": ("बुरुंडी", "गितेगा"),
    "CV": ("केप वर्डे", "प्राइया"),
    "CM": ("कैमरून", "याओंदे"),
    "CF": ("मध्य अफ़्रीकी गणराज्य", "बांगुई"),
    "TD": ("चाड", "एनजामेना"),
    "KM": ("कोमोरोस", "मोरोनी"),
    "CD": ("कांगो लोकतांत्रिक गणराज्य", "किंशासा"),
    "DJ": ("जिबूती", "जिबूती"),
    "EG": ("मिस्र", "काहिरा"),
    "GQ": ("भूमध्यरेखीय गिनी", "मलाबो"),
    "ER": ("इरिट्रिया", "अस्मारा"),
    "SZ": ("इस्वातिनी", "म्बाबाने"),
    "ET": ("इथियोपिया", "अदीस अबाबा"),
    "GA": ("गैबॉन", "लिब्रेविल"),
    "GM": ("गाम्बिया", "बंजुल"),
    "GH": ("घाना", "अक्करा"),
    "GN": ("गिनी", "कोनाक्री"),
    "GW": ("गिनी-बिसाऊ", "बिसाऊ"),
    "CI": ("आइवरी कोस्ट", "यामूसोक्रो"),
    "KE": ("केन्या", "नैरोबी"),
    "LS": ("लेसोथो", "मासेरू"),
    "LR": ("लाइबेरिया", "मोनरोविया"),
    "LY": ("लीबिया", "त्रिपोली"),
    "MG": ("मेडागास्कर", "अंटानानारिवो"),
    "MW": ("मलावी", "लिलोंग्वे"),
    "ML": ("माली", "बमाको"),
    "MR": ("मॉरिटानिया", "नौआकशॉट"),
    "MU": ("मॉरीशस", "पोर्ट लुई"),
    "MA": ("मोरक्को", "रबात"),
    "MZ": ("मोज़ाम्बिक", "मापुतो"),
    "NA": ("नामीबिया", "विंडहोक"),
    "NE": ("नाइजर", "नियामे"),
    "NG": ("नाइजीरिया", "अबुजा"),
    "CG": ("कांगो गणराज्य", "ब्राज़ाविल"),
    "RW": ("रवांडा", "किगाली"),
    "ST": ("साओ टोमे और प्रिंसिपे", "साओ टोमे"),
    "SN": ("सेनेगल", "डकार"),
    "SC": ("सेशेल्स", "विक्टोरिया"),
    "SL": ("सिएरा लियोन", "फ़्रीटाउन"),
    "SO": ("सोमालिया", "मोगादिशू"),
    "ZA": ("दक्षिण अफ़्रीका", "प्रिटोरिया"),
    "SS": ("दक्षिण सूडान", "जुबा"),
    "SD": ("सूडान", "खार्तूम"),
    "TZ": ("तंज़ानिया", "डोडोमा"),
    "TG": ("टोगो", "लोमे"),
    "TN": ("ट्यूनीशिया", "ट्यूनिस"),
    "UG": ("युगांडा", "कंपाला"),
    "ZM": ("ज़ाम्बिया", "लुसाका"),
    "ZW": ("ज़िम्बाब्वे", "हरारे"),
    "AF": ("अफ़ग़ानिस्तान", "काबुल"),
    "AM": ("आर्मेनिया", "येरेवान"),
    "AZ": ("अज़रबैजान", "बाकू"),
    "BH": ("बहरीन", "मनामा"),
    "BD": ("बांग्लादेश", "ढाका"),
    "BT": ("भूटान", "थिम्पू"),
    "BN": ("ब्रुनेई", "बंदर सेरी बेगवान"),
    "KH": ("कंबोडिया", "नोम पेन्ह"),
    "CN": ("चीन", "बीजिंग"),
    "CY": ("साइप्रस", "निकोसिया"),
    "GE": ("जॉर्जिया", "त्बिलिसी"),
    "IN": ("भारत", "नई दिल्ली"),
    "ID": ("इंडोनेशिया", "जकार्ता"),
    "IR": ("ईरान", "तेहरान"),
    "IQ": ("इराक़", "बग़दाद"),
    "IL": ("इज़राइल", "यरुशलम"),
    "JP": ("जापान", "टोक्यो"),
    "JO": ("जॉर्डन", "अम्मान"),
    "KZ": ("कज़ाख़स्तान", "अस्ताना"),
    "KW": ("कुवैत", "कुवैत सिटी"),
    "KG": ("किर्गिज़स्तान", "बिश्केक"),
    "LA": ("लाओस", "वियनतियाने"),
    "LB": ("लेबनान", "बेरूत"),
    "MY": ("मलेशिया", "कुआलालंपुर"),
    "MV": ("मालदीव", "माले"),
    "MN": ("मंगोलिया", "उलानबटोर"),
    "MM": ("म्यांमार", "नेपीडॉ"),
    "NP": ("नेपाल", "काठमांडू"),
    "KP": ("उत्तर कोरिया", "प्योंगयांग"),
    "OM": ("ओमान", "मस्कट"),
    "PK": ("पाकिस्तान", "इस्लामाबाद"),
    "PH": ("फ़िलीपींस", "मनीला"),
    "PS": ("फ़िलिस्तीन", "रामल्ला"),
    "QA": ("क़तर", "दोहा"),
    "SA": ("सऊदी अरब", "रियाद"),
    "SG": ("सिंगापुर", "सिंगापुर"),
    "KR": ("दक्षिण कोरिया", "सियोल"),
    "LK": ("श्रीलंका", "श्री जयवर्धनेपुरा कोट्टे"),
    "SY": ("सीरिया", "दमिश्क"),
    "TW": ("ताइवान", "ताइपे"),
    "TJ": ("ताजिकिस्तान", "दुशांबे"),
    "TH": ("थाईलैंड", "बैंकॉक"),
    "TL": ("पूर्वी तिमोर", "दिली"),
    "TR": ("तुर्की", "अंकारा"),
    "TM": ("तुर्कमेनिस्तान", "अश्गाबात"),
    "AE": ("संयुक्त अरब अमीरात", "अबू धाबी"),
    "UZ": ("उज़्बेकिस्तान", "ताशकंद"),
    "VN": ("वियतनाम", "हनोई"),
    "YE": ("यमन", "साना"),
    "AL": ("अल्बानिया", "तिराना"),
    "AD": ("अंडोरा", "अंडोरा ला वेला"),
    "AT": ("ऑस्ट्रिया", "वियना"),
    "BY": ("बेलारूस", "मिन्स्क"),
    "BE": ("बेल्जियम", "ब्रुसेल्स"),
    "BA": ("बोस्निया और हर्ज़ेगोविना", "साराजेवो"),
    "BG": ("बुल्गारिया", "सोफ़िया"),
    "HR": ("क्रोएशिया", "ज़ाग्रेब"),
    "CZ": ("चेक गणराज्य", "प्राग"),
    "DK": ("डेनमार्क", "कोपेनहेगन"),
    "EE": ("एस्टोनिया", "तेलिन"),
    "FI": ("फ़िनलैंड", "हेलसिंकी"),
    "FR": ("फ़्रान्स", "पेरिस"),
    "DE": ("जर्मनी", "बर्लिन"),
    "GR": ("यूनान", "एथेंस"),
    "HU": ("हंगरी", "बुडापेस्ट"),
    "IS": ("आइसलैंड", "रेक्याविक"),
    "IE": ("आयरलैंड", "डबलिन"),
    "IT": ("इटली", "रोम"),
    "XK": ("कोसोवो", "प्रिश्तिना"),
    "LV": ("लातविया", "रीगा"),
    "LI": ("लिख्टेंश्टाइन", "वादुज़"),
    "LT": ("लिथुआनिया", "विल्नियस"),
    "LU": ("लक्ज़मबर्ग", "लक्ज़मबर्ग"),
    "MT": ("माल्टा", "वालेटा"),
    "MD": ("मोल्दोवा", "किशिनेव"),
    "MC": ("मोनाको", "मोनाको"),
    "ME": ("मोंटेनेग्रो", "पोदगोरिका"),
    "NL": ("नीदरलैंड", "एम्स्टर्डम"),
    "MK": ("उत्तर मैसिडोनिया", "स्कोप्ये"),
    "NO": ("नॉर्वे", "ओस्लो"),
    "PL": ("पोलैंड", "वारसॉ"),
    "PT": ("पुर्तगाल", "लिस्बन"),
    "RO": ("रोमानिया", "बुख़ारेस्ट"),
    "RU": ("रूस", "मास्को"),
    "SM": ("सैन मरीनो", "सैन मरीनो"),
    "RS": ("सर्बिया", "बेलग्रेड"),
    "SK": ("स्लोवाकिया", "ब्रातिस्लावा"),
    "SI": ("स्लोवेनिया", "ल्युब्लियाना"),
    "ES": ("स्पेन", "मैड्रिड"),
    "SE": ("स्वीडन", "स्टॉकहोम"),
    "CH": ("स्विट्ज़रलैंड", "बर्न"),
    "UA": ("यूक्रेन", "कीव"),
    "GB": ("यूनाइटेड किंगडम", "लंदन"),
    "VA": ("वैटिकन सिटी", "वैटिकन सिटी"),
    "AG": ("एंटीगुआ और बारबुडा", "सेंट जॉन्स"),
    "BS": ("बहामास", "नासाउ"),
    "BB": ("बारबाडोस", "ब्रिजटाउन"),
    "BZ": ("बेलीज़", "बेल्मोपान"),
    "CA": ("कनाडा", "ओटावा"),
    "CR": ("कोस्टा रिका", "सैन होज़े"),
    "CU": ("क्यूबा", "हवाना"),
    "DM": ("डोमिनिका", "रोज़ो"),
    "DO": ("डोमिनिकन गणराज्य", "सेंटो डोमिंगो"),
    "SV": ("अल साल्वाडोर", "सैन साल्वाडोर"),
    "GD": ("ग्रेनेडा", "सेंट जॉर्ज"),
    "GT": ("ग्वाटेमाला", "ग्वाटेमाला सिटी"),
    "HT": ("हैती", "पोर्ट-औ-प्रिंस"),
    "HN": ("होंडुरास", "तेगुसिगाल्पा"),
    "JM": ("जमैका", "किंग्स्टन"),
    "MX": ("मेक्सिको", "मेक्सिको सिटी"),
    "NI": ("निकारागुआ", "मानागुआ"),
    "PA": ("पनामा", "पनामा सिटी"),
    "KN": ("सेंट किट्स और नेविस", "बैसटेर"),
    "LC": ("सेंट लूसिया", "कास्ट्रीज़"),
    "VC": ("सेंट विंसेंट और ग्रेनेडाइंस", "किंग्सटाउन"),
    "TT": ("त्रिनिदाद और टोबैगो", "पोर्ट ऑफ़ स्पेन"),
    "US": ("संयुक्त राज्य अमेरिका", "वॉशिंगटन, डी.सी."),
    "AU": ("ऑस्ट्रेलिया", "कैनबरा"),
    "FJ": ("फ़िजी", "सुवा"),
    "KI": ("किरिबाती", "दक्षिण तरावा"),
    "MH": ("मार्शल द्वीप", "माजुरो"),
    "FM": ("माइक्रोनेशिया", "पालिकिर"),
    "NR": ("नाउरू", "यारेन"),
    "NZ": ("न्यूज़ीलैंड", "वेलिंगटन"),
    "PW": ("पलाऊ", "नगेरुलमुद"),
    "PG": ("पापुआ न्यू गिनी", "पोर्ट मोरेस्बी"),
    "WS": ("समोआ", "एपिया"),
    "SB": ("सोलोमन द्वीप", "होनियारा"),
    "TO": ("टोंगा", "नुकूअलोफ़ा"),
    "TV": ("तुवालू", "फ़नाफ़ुति"),
    "VU": ("वानुआतू", "पोर्ट विला"),
    "AR": ("अर्जेंटीना", "ब्यूनस आयर्स"),
    "BO": ("बोलीविया", "सुक्रे"),
    "BR": ("ब्राज़ील", "ब्रासीलिया"),
    "CL": ("चिली", "सैंटियागो"),
    "CO": ("कोलंबिया", "बोगोटा"),
    "EC": ("इक्वाडोर", "क्विटो"),
    "GY": ("गुयाना", "जॉर्जटाउन"),
    "PY": ("पैराग्वे", "असुंसियोन"),
    "PE": ("पेरू", "लीमा"),
    "SR": ("सूरीनाम", "पारामारिबो"),
    "UY": ("उरुग्वे", "मोंटेवीडियो"),
    "VE": ("वेनेज़ुएला", "काराकस"),
}

RIVERS: dict[str, str] = {
    "nile": "नील नदी",
    "amazon": "अमेज़न नदी",
    "yangtze": "यांग्त्ज़ी नदी",
    "mississippi": "मिसिसिपी नदी",
    "yenisei": "येनिसेई नदी",
    "yellow-river": "ह्वांग हो",
    "ob": "ओब नदी",
    "congo": "कांगो नदी",
    "lena": "लीना नदी",
    "niger": "नाइजर नदी",
    "mekong": "मेकांग नदी",
    "missouri": "मिसौरी नदी",
    "volga": "वोल्गा नदी",
    "zambezi": "ज़ाम्बेज़ी नदी",
    "ganges": "गंगा",
    "indus": "सिंधु नदी",
    "murray": "मरे नदी",
    "euphrates": "फ़रात नदी",
    "tigris": "दजला नदी",
    "rhine": "राइन नदी",
    "danube": "डैन्यूब नदी",
    "colorado": "कोलोराडो नदी",
    "columbia": "कोलंबिया नदी",
    "irrawaddy": "इरावदी नदी",
    "orange": "ऑरेंज नदी",
    "parana": "पाराना नदी",
    "amur": "अमूर नदी",
    "dnieper": "नीपर नदी",
    "senegal-river": "सेनेगल नदी",
    "orinoco": "ओरिनोको नदी",
    "sao-francisco": "साओ फ़्रांसिस्को नदी",
    "tocantins": "टोकैंटिन्स नदी",
}

MOUNTAINS: dict[str, str] = {
    "himalayas": "हिमालय",
    "andes": "एंडीज़ पर्वत",
    "rockies": "रॉकी पर्वत",
    "alps": "आल्प्स पर्वत",
    "great-dividing-range": "ग्रेट डिवाइडिंग रेंज",
    "kunlun": "कुनलुन पर्वत",
    "tian-shan": "तियेन शान",
    "altai": "अल्ताई पर्वत",
    "caucasus": "काकेशस पर्वत",
    "pyrenees": "पिरेनीज़ पर्वत",
    "carpathians": "कार्पेथियन पर्वत",
    "appalachians": "अपलाचियन पर्वत",
    "atlas": "एटलस पर्वत",
    "drakensberg": "ड्रेकेन्सबर्ग पर्वत",
    "ethiopian-highlands": "इथियोपियाई उच्चभूमि",
    "scandinavian-mountains": "स्कैंडिनेवियाई पर्वत",
    "hindu-kush": "हिंदू कुश",
    "karakoram": "काराकोरम",
    "pamir": "पामीर पर्वत",
    "sierra-nevada-us": "सिएरा नेवादा",
    "southern-alps": "दक्षिणी आल्प्स",
    "zagros": "ज़ाग्रोस पर्वत",
    "eastern-rift-highlands": "पूर्वी दरार उच्चभूमि",
}

SEAS: dict[str, str] = {
    "pacific": "प्रशांत महासागर",
    "atlantic": "अटलांटिक महासागर",
    "indian": "हिंद महासागर",
    "southern": "दक्षिणी महासागर",
    "arctic": "आर्कटिक महासागर",
    "mediterranean": "भूमध्य सागर",
    "caribbean": "कैरिबियन सागर",
    "south-china": "दक्षिण चीन सागर",
    "bering": "बेरिंग सागर",
    "gulf-of-mexico": "मेक्सिको की खाड़ी",
    "north-sea": "उत्तरी सागर",
    "red-sea": "लाल सागर",
    "black-sea": "काला सागर",
    "caspian-sea": "कैस्पियन सागर",
    "persian-gulf": "फ़ारस की खाड़ी",
    "east-china": "पूर्वी चीन सागर",
    "bay-of-bengal": "बंगाल की खाड़ी",
    "arabian-sea": "अरब सागर",
    "coral-sea": "कोरल सागर",
    "tasman-sea": "तस्मान सागर",
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
        raise SystemExit(f"{filename}: no Hindi mapping for ids: {missing}")
    new_data = []
    for obj in data:
        oid = obj["id"]
        entry = names[oid]
        name_hi = entry[0] if has_capital else entry
        obj = insert_after(obj, "name", "name_hi", name_hi)
        if has_capital:
            obj = insert_after(obj, "capital", "capital_hi", entry[1])
        new_data.append(obj)
    path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"{filename}: wrote name_hi for {len(new_data)} entities"
        + (" + capital_hi" if has_capital else "")
    )


def main() -> None:
    process("countries.json", COUNTRIES, has_capital=True)
    process("rivers.json", RIVERS, has_capital=False)
    process("mountains.json", MOUNTAINS, has_capital=False)
    process("seas.json", SEAS, has_capital=False)


if __name__ == "__main__":
    main()
