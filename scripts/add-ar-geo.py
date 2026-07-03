#!/usr/bin/env python3
"""One-shot helper: inject standard Arabic exonyms (name_ar / capital_ar) into the source geo JSONs
for story 009 (Arabic content).

Reads the curated id -> Arabic maps below and writes `name_ar` (all entities) and `capital_ar`
(countries only) into each object in countries.json / rivers.json / mountains.json / seas.json, placed
immediately after the base `name` / `capital` key so the new columns sit beside their siblings.
Idempotent: re-running overwrites the ar columns with the curated values. Preserves all other keys and
their order, and round-trips JSON with ensure_ascii=False + 2-space indent to match the existing files.

The translations are standard, well-established Modern Standard Arabic (MSA) exonyms in Arabic script.
Arabic is an RTL, non-Latin script, so the values are normal Arabic text — the file stores them as
ordinary strings (RTL rendering is the app's job, not the data's). No blank or English-placeholder
values — the strict completeness gate fails on any missing/blank value.
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RES = REPO_ROOT / "Hanahuac" / "Resources"

# id -> (name_ar, capital_ar)
COUNTRIES: dict[str, tuple[str, str]] = {
    "DZ": ("الجزائر", "الجزائر"),
    "AO": ("أنغولا", "لواندا"),
    "BJ": ("بنين", "بورتو نوفو"),
    "BW": ("بوتسوانا", "غابورون"),
    "BF": ("بوركينا فاسو", "واغادوغو"),
    "BI": ("بوروندي", "غيتيغا"),
    "CV": ("الرأس الأخضر", "برايا"),
    "CM": ("الكاميرون", "ياوندي"),
    "CF": ("جمهورية أفريقيا الوسطى", "بانغي"),
    "TD": ("تشاد", "نجامينا"),
    "KM": ("جزر القمر", "موروني"),
    "CD": ("جمهورية الكونغو الديمقراطية", "كينشاسا"),
    "DJ": ("جيبوتي", "جيبوتي"),
    "EG": ("مصر", "القاهرة"),
    "GQ": ("غينيا الاستوائية", "مالابو"),
    "ER": ("إريتريا", "أسمرة"),
    "SZ": ("إسواتيني", "مبابان"),
    "ET": ("إثيوبيا", "أديس أبابا"),
    "GA": ("الغابون", "ليبرفيل"),
    "GM": ("غامبيا", "بانجول"),
    "GH": ("غانا", "أكرا"),
    "GN": ("غينيا", "كوناكري"),
    "GW": ("غينيا بيساو", "بيساو"),
    "CI": ("ساحل العاج", "ياموسوكرو"),
    "KE": ("كينيا", "نيروبي"),
    "LS": ("ليسوتو", "ماسيرو"),
    "LR": ("ليبيريا", "مونروفيا"),
    "LY": ("ليبيا", "طرابلس"),
    "MG": ("مدغشقر", "أنتاناناريفو"),
    "MW": ("مالاوي", "ليلونغوي"),
    "ML": ("مالي", "باماكو"),
    "MR": ("موريتانيا", "نواكشوط"),
    "MU": ("موريشيوس", "بورت لويس"),
    "MA": ("المغرب", "الرباط"),
    "MZ": ("موزمبيق", "مابوتو"),
    "NA": ("ناميبيا", "ويندهوك"),
    "NE": ("النيجر", "نيامي"),
    "NG": ("نيجيريا", "أبوجا"),
    "CG": ("جمهورية الكونغو", "برازافيل"),
    "RW": ("رواندا", "كيغالي"),
    "ST": ("ساو تومي وبرينسيبي", "ساو تومي"),
    "SN": ("السنغال", "داكار"),
    "SC": ("سيشل", "فيكتوريا"),
    "SL": ("سيراليون", "فريتاون"),
    "SO": ("الصومال", "مقديشو"),
    "ZA": ("جنوب أفريقيا", "بريتوريا"),
    "SS": ("جنوب السودان", "جوبا"),
    "SD": ("السودان", "الخرطوم"),
    "TZ": ("تنزانيا", "دودوما"),
    "TG": ("توغو", "لومي"),
    "TN": ("تونس", "تونس"),
    "UG": ("أوغندا", "كمبالا"),
    "ZM": ("زامبيا", "لوساكا"),
    "ZW": ("زيمبابوي", "هراري"),
    "AF": ("أفغانستان", "كابول"),
    "AM": ("أرمينيا", "يريفان"),
    "AZ": ("أذربيجان", "باكو"),
    "BH": ("البحرين", "المنامة"),
    "BD": ("بنغلاديش", "دكا"),
    "BT": ("بوتان", "تيمفو"),
    "BN": ("بروناي", "بندر سري بكاوان"),
    "KH": ("كمبوديا", "بنوم بنه"),
    "CN": ("الصين", "بكين"),
    "CY": ("قبرص", "نيقوسيا"),
    "GE": ("جورجيا", "تبليسي"),
    "IN": ("الهند", "نيودلهي"),
    "ID": ("إندونيسيا", "جاكرتا"),
    "IR": ("إيران", "طهران"),
    "IQ": ("العراق", "بغداد"),
    "IL": ("إسرائيل", "القدس"),
    "JP": ("اليابان", "طوكيو"),
    "JO": ("الأردن", "عمّان"),
    "KZ": ("كازاخستان", "أستانا"),
    "KW": ("الكويت", "مدينة الكويت"),
    "KG": ("قيرغيزستان", "بيشكك"),
    "LA": ("لاوس", "فيينتيان"),
    "LB": ("لبنان", "بيروت"),
    "MY": ("ماليزيا", "كوالالمبور"),
    "MV": ("جزر المالديف", "ماليه"),
    "MN": ("منغوليا", "أولان باتور"),
    "MM": ("ميانمار", "نايبيداو"),
    "NP": ("نيبال", "كاتماندو"),
    "KP": ("كوريا الشمالية", "بيونغ يانغ"),
    "OM": ("عُمان", "مسقط"),
    "PK": ("باكستان", "إسلام آباد"),
    "PH": ("الفلبين", "مانيلا"),
    "PS": ("فلسطين", "رام الله"),
    "QA": ("قطر", "الدوحة"),
    "SA": ("المملكة العربية السعودية", "الرياض"),
    "SG": ("سنغافورة", "سنغافورة"),
    "KR": ("كوريا الجنوبية", "سيول"),
    "LK": ("سريلانكا", "سري جاياواردنابورا كوتي"),
    "SY": ("سوريا", "دمشق"),
    "TW": ("تايوان", "تايبيه"),
    "TJ": ("طاجيكستان", "دوشنبه"),
    "TH": ("تايلاند", "بانكوك"),
    "TL": ("تيمور الشرقية", "ديلي"),
    "TR": ("تركيا", "أنقرة"),
    "TM": ("تركمانستان", "عشق آباد"),
    "AE": ("الإمارات العربية المتحدة", "أبوظبي"),
    "UZ": ("أوزبكستان", "طشقند"),
    "VN": ("فيتنام", "هانوي"),
    "YE": ("اليمن", "صنعاء"),
    "AL": ("ألبانيا", "تيرانا"),
    "AD": ("أندورا", "أندورا لا فيلا"),
    "AT": ("النمسا", "فيينا"),
    "BY": ("بيلاروسيا", "مينسك"),
    "BE": ("بلجيكا", "بروكسل"),
    "BA": ("البوسنة والهرسك", "سراييفو"),
    "BG": ("بلغاريا", "صوفيا"),
    "HR": ("كرواتيا", "زغرب"),
    "CZ": ("التشيك", "براغ"),
    "DK": ("الدنمارك", "كوبنهاغن"),
    "EE": ("إستونيا", "تالين"),
    "FI": ("فنلندا", "هلسنكي"),
    "FR": ("فرنسا", "باريس"),
    "DE": ("ألمانيا", "برلين"),
    "GR": ("اليونان", "أثينا"),
    "HU": ("المجر", "بودابست"),
    "IS": ("آيسلندا", "ريكيافيك"),
    "IE": ("أيرلندا", "دبلن"),
    "IT": ("إيطاليا", "روما"),
    "XK": ("كوسوفو", "بريشتينا"),
    "LV": ("لاتفيا", "ريغا"),
    "LI": ("ليختنشتاين", "فادوز"),
    "LT": ("ليتوانيا", "فيلنيوس"),
    "LU": ("لوكسمبورغ", "لوكسمبورغ"),
    "MT": ("مالطا", "فاليتا"),
    "MD": ("مولدوفا", "كيشيناو"),
    "MC": ("موناكو", "موناكو"),
    "ME": ("الجبل الأسود", "بودغوريتسا"),
    "NL": ("هولندا", "أمستردام"),
    "MK": ("مقدونيا الشمالية", "سكوبيه"),
    "NO": ("النرويج", "أوسلو"),
    "PL": ("بولندا", "وارسو"),
    "PT": ("البرتغال", "لشبونة"),
    "RO": ("رومانيا", "بوخارست"),
    "RU": ("روسيا", "موسكو"),
    "SM": ("سان مارينو", "سان مارينو"),
    "RS": ("صربيا", "بلغراد"),
    "SK": ("سلوفاكيا", "براتيسلافا"),
    "SI": ("سلوفينيا", "ليوبليانا"),
    "ES": ("إسبانيا", "مدريد"),
    "SE": ("السويد", "ستوكهولم"),
    "CH": ("سويسرا", "برن"),
    "UA": ("أوكرانيا", "كييف"),
    "GB": ("المملكة المتحدة", "لندن"),
    "VA": ("مدينة الفاتيكان", "مدينة الفاتيكان"),
    "AG": ("أنتيغوا وباربودا", "سانت جونز"),
    "BS": ("الباهاما", "ناساو"),
    "BB": ("باربادوس", "بريدجتاون"),
    "BZ": ("بليز", "بلموبان"),
    "CA": ("كندا", "أوتاوا"),
    "CR": ("كوستاريكا", "سان خوسيه"),
    "CU": ("كوبا", "هافانا"),
    "DM": ("دومينيكا", "روزو"),
    "DO": ("جمهورية الدومينيكان", "سانتو دومينغو"),
    "SV": ("السلفادور", "سان سلفادور"),
    "GD": ("غرينادا", "سانت جورجز"),
    "GT": ("غواتيمالا", "غواتيمالا سيتي"),
    "HT": ("هايتي", "بورت أو برانس"),
    "HN": ("هندوراس", "تيغوسيغالبا"),
    "JM": ("جامايكا", "كينغستون"),
    "MX": ("المكسيك", "مدينة مكسيكو"),
    "NI": ("نيكاراغوا", "ماناغوا"),
    "PA": ("بنما", "مدينة بنما"),
    "KN": ("سانت كيتس ونيفيس", "باستير"),
    "LC": ("سانت لوسيا", "كاستريس"),
    "VC": ("سانت فنسنت والغرينادين", "كينغستاون"),
    "TT": ("ترينيداد وتوباغو", "بورت أوف سبين"),
    "US": ("الولايات المتحدة", "واشنطن العاصمة"),
    "AU": ("أستراليا", "كانبيرا"),
    "FJ": ("فيجي", "سوفا"),
    "KI": ("كيريباتي", "جنوب تاراوا"),
    "MH": ("جزر مارشال", "ماجورو"),
    "FM": ("ميكرونيزيا", "باليكير"),
    "NR": ("ناورو", "يارين"),
    "NZ": ("نيوزيلندا", "ولينغتون"),
    "PW": ("بالاو", "نغيرولمود"),
    "PG": ("بابوا غينيا الجديدة", "بورت مورسبي"),
    "WS": ("ساموا", "آبيا"),
    "SB": ("جزر سليمان", "هونيارا"),
    "TO": ("تونغا", "نوكوألوفا"),
    "TV": ("توفالو", "فونافوتي"),
    "VU": ("فانواتو", "بورت فيلا"),
    "AR": ("الأرجنتين", "بوينس آيرس"),
    "BO": ("بوليفيا", "سوكري"),
    "BR": ("البرازيل", "برازيليا"),
    "CL": ("تشيلي", "سانتياغو"),
    "CO": ("كولومبيا", "بوغوتا"),
    "EC": ("الإكوادور", "كيتو"),
    "GY": ("غيانا", "جورجتاون"),
    "PY": ("باراغواي", "أسونسيون"),
    "PE": ("بيرو", "ليما"),
    "SR": ("سورينام", "باراماريبو"),
    "UY": ("الأوروغواي", "مونتيفيديو"),
    "VE": ("فنزويلا", "كاراكاس"),
}

RIVERS: dict[str, str] = {
    "nile": "نهر النيل",
    "amazon": "نهر الأمازون",
    "yangtze": "نهر اليانغتسي",
    "mississippi": "نهر المسيسيبي",
    "yenisei": "نهر ينيسي",
    "yellow-river": "النهر الأصفر",
    "ob": "نهر أوب",
    "congo": "نهر الكونغو",
    "lena": "نهر لينا",
    "niger": "نهر النيجر",
    "mekong": "نهر الميكونغ",
    "missouri": "نهر ميزوري",
    "volga": "نهر الفولغا",
    "zambezi": "نهر زامبيزي",
    "ganges": "نهر الغانج",
    "indus": "نهر السند",
    "murray": "نهر موراي",
    "euphrates": "نهر الفرات",
    "tigris": "نهر دجلة",
    "rhine": "نهر الراين",
    "danube": "نهر الدانوب",
    "colorado": "نهر كولورادو",
    "columbia": "نهر كولومبيا",
    "irrawaddy": "نهر إيراوادي",
    "orange": "نهر أورانج",
    "parana": "نهر بارانا",
    "amur": "نهر آمور",
    "dnieper": "نهر دنيبر",
    "senegal-river": "نهر السنغال",
    "orinoco": "نهر أورينوكو",
    "sao-francisco": "نهر ساو فرانسيسكو",
    "tocantins": "نهر توكانتينس",
}

MOUNTAINS: dict[str, str] = {
    "himalayas": "جبال الهيمالايا",
    "andes": "جبال الأنديز",
    "rockies": "جبال روكي",
    "alps": "جبال الألب",
    "great-dividing-range": "السلسلة الفاصلة الكبرى",
    "kunlun": "جبال كونلون",
    "tian-shan": "جبال تيان شان",
    "altai": "جبال ألتاي",
    "caucasus": "جبال القوقاز",
    "pyrenees": "جبال البيرينيه",
    "carpathians": "جبال الكاربات",
    "appalachians": "جبال الأبلاش",
    "atlas": "جبال الأطلس",
    "drakensberg": "جبال دراكنزبرغ",
    "ethiopian-highlands": "المرتفعات الإثيوبية",
    "scandinavian-mountains": "الجبال الإسكندنافية",
    "hindu-kush": "جبال هندوكوش",
    "karakoram": "جبال قراقورم",
    "pamir": "جبال بامير",
    "sierra-nevada-us": "سييرا نيفادا",
    "southern-alps": "الألب الجنوبية",
    "zagros": "جبال زاغروس",
    "eastern-rift-highlands": "مرتفعات الوادي المتصدع الشرقي",
}

SEAS: dict[str, str] = {
    "pacific": "المحيط الهادئ",
    "atlantic": "المحيط الأطلسي",
    "indian": "المحيط الهندي",
    "southern": "المحيط الجنوبي",
    "arctic": "المحيط المتجمد الشمالي",
    "mediterranean": "البحر الأبيض المتوسط",
    "caribbean": "البحر الكاريبي",
    "south-china": "بحر الصين الجنوبي",
    "bering": "بحر بيرينغ",
    "gulf-of-mexico": "خليج المكسيك",
    "north-sea": "بحر الشمال",
    "red-sea": "البحر الأحمر",
    "black-sea": "البحر الأسود",
    "caspian-sea": "بحر قزوين",
    "persian-gulf": "الخليج العربي",
    "east-china": "بحر الصين الشرقي",
    "bay-of-bengal": "خليج البنغال",
    "arabian-sea": "بحر العرب",
    "coral-sea": "بحر المرجان",
    "tasman-sea": "بحر تسمان",
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
        raise SystemExit(f"{filename}: no Arabic mapping for ids: {missing}")
    new_data = []
    for obj in data:
        oid = obj["id"]
        entry = names[oid]
        name_ar = entry[0] if has_capital else entry
        obj = insert_after(obj, "name", "name_ar", name_ar)
        if has_capital:
            obj = insert_after(obj, "capital", "capital_ar", entry[1])
        new_data.append(obj)
    path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"{filename}: wrote name_ar for {len(new_data)} entities"
        + (" + capital_ar" if has_capital else "")
    )


def main() -> None:
    process("countries.json", COUNTRIES, has_capital=True)
    process("rivers.json", RIVERS, has_capital=False)
    process("mountains.json", MOUNTAINS, has_capital=False)
    process("seas.json", SEAS, has_capital=False)


if __name__ == "__main__":
    main()
