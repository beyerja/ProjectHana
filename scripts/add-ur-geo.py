#!/usr/bin/env python3
"""One-shot helper: inject standard Urdu exonyms (name_ur / capital_ur) into the source geo JSONs
for story 010 (Urdu content).

Reads the curated id -> Urdu maps below and writes `name_ur` (all entities) and `capital_ur`
(countries only) into each object in countries.json / rivers.json / mountains.json / seas.json, placed
immediately after the matching `name_ar` / `capital_ar` key so the new ur columns sit beside their
ar siblings (and fall back to after `name` / `capital` if the ar column is absent). Idempotent:
re-running overwrites the ur columns with the curated values. Preserves all other keys and their
order, and round-trips JSON with ensure_ascii=False + 2-space indent to match the existing files.

The translations are standard, well-established Urdu exonyms in the Perso-Arabic (Nastaʿlīq) script.
Urdu is an RTL, non-Latin script with its own vocabulary and letters (it is NOT Arabic), so the values
are normal Urdu text — the file stores them as ordinary strings (RTL rendering is the app's job, not
the data's). No blank or English-placeholder values — the strict completeness gate fails on any
missing/blank value.
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RES = REPO_ROOT / "Hanahuac" / "Resources"

# id -> (name_ur, capital_ur)
COUNTRIES: dict[str, tuple[str, str]] = {
    "DZ": ("الجزائر", "الجزائر"),
    "AO": ("انگولا", "لوآنڈا"),
    "BJ": ("بینن", "پورٹو نوو"),
    "BW": ("بوٹسوانا", "گیبرون"),
    "BF": ("برکینا فاسو", "اوآگادوگو"),
    "BI": ("برونڈی", "گیتیگا"),
    "CV": ("کیپ ورڈی", "پرایا"),
    "CM": ("کیمرون", "یاؤنڈے"),
    "CF": ("وسطی افریقی جمہوریہ", "بانگوئی"),
    "TD": ("چاڈ", "اینجامینا"),
    "KM": ("کوموروس", "مورونی"),
    "CD": ("جمہوری جمہوریہ کانگو", "کنشاسا"),
    "DJ": ("جبوتی", "جبوتی"),
    "EG": ("مصر", "قاہرہ"),
    "GQ": ("استوائی گنی", "مالابو"),
    "ER": ("اریٹیریا", "اسمارہ"),
    "SZ": ("ایسواتینی", "مبابانے"),
    "ET": ("ایتھوپیا", "ادیس ابابا"),
    "GA": ("گیبون", "لیبرویل"),
    "GM": ("گیمبیا", "بانجول"),
    "GH": ("گھانا", "اکرا"),
    "GN": ("گنی", "کوناکری"),
    "GW": ("گنی بساؤ", "بساؤ"),
    "CI": ("آئیوری کوسٹ", "یاموسوکرو"),
    "KE": ("کینیا", "نیروبی"),
    "LS": ("لیسوتھو", "ماسیرو"),
    "LR": ("لائبیریا", "مونروویا"),
    "LY": ("لیبیا", "طرابلس"),
    "MG": ("مڈغاسکر", "انتاناناریوو"),
    "MW": ("ملاوی", "لیلونگوے"),
    "ML": ("مالی", "باماکو"),
    "MR": ("موریتانیہ", "نواکشوط"),
    "MU": ("ماریشس", "پورٹ لوئس"),
    "MA": ("مراکش", "رباط"),
    "MZ": ("موزمبیق", "ماپوتو"),
    "NA": ("نمیبیا", "ونڈہوک"),
    "NE": ("نائجر", "نیامی"),
    "NG": ("نائجیریا", "ابوجا"),
    "CG": ("جمہوریہ کانگو", "برازاویل"),
    "RW": ("روانڈا", "کیگالی"),
    "ST": ("ساؤ ٹومے و پرنسپے", "ساؤ ٹومے"),
    "SN": ("سینیگال", "ڈاکار"),
    "SC": ("سیشیلز", "وکٹوریہ"),
    "SL": ("سیرالیون", "فری ٹاؤن"),
    "SO": ("صومالیہ", "موغادیشو"),
    "ZA": ("جنوبی افریقہ", "پریٹوریا"),
    "SS": ("جنوبی سوڈان", "جوبا"),
    "SD": ("سوڈان", "خرطوم"),
    "TZ": ("تنزانیہ", "دودوما"),
    "TG": ("ٹوگو", "لومے"),
    "TN": ("تیونس", "تیونس"),
    "UG": ("یوگنڈا", "کمپالا"),
    "ZM": ("زیمبیا", "لوساکا"),
    "ZW": ("زمبابوے", "ہرارے"),
    "AF": ("افغانستان", "کابل"),
    "AM": ("آرمینیا", "یریوان"),
    "AZ": ("آذربائیجان", "باکو"),
    "BH": ("بحرین", "منامہ"),
    "BD": ("بنگلہ دیش", "ڈھاکہ"),
    "BT": ("بھوٹان", "تھمپو"),
    "BN": ("برونائی", "بندر سری بگاوان"),
    "KH": ("کمبوڈیا", "نوم پنہ"),
    "CN": ("چین", "بیجنگ"),
    "CY": ("قبرص", "نیکوسیا"),
    "GE": ("جارجیا", "تبلیسی"),
    "IN": ("بھارت", "نئی دہلی"),
    "ID": ("انڈونیشیا", "جکارتہ"),
    "IR": ("ایران", "تہران"),
    "IQ": ("عراق", "بغداد"),
    "IL": ("اسرائیل", "یروشلم"),
    "JP": ("جاپان", "ٹوکیو"),
    "JO": ("اردن", "عمان"),
    "KZ": ("قازقستان", "آستانہ"),
    "KW": ("کویت", "کویت شہر"),
    "KG": ("کرغیزستان", "بشکیک"),
    "LA": ("لاؤس", "وینتیان"),
    "LB": ("لبنان", "بیروت"),
    "MY": ("ملائیشیا", "کوالالمپور"),
    "MV": ("مالدیپ", "مالے"),
    "MN": ("منگولیا", "اولان باتور"),
    "MM": ("میانمار", "نائے پی تاؤ"),
    "NP": ("نیپال", "کھٹمنڈو"),
    "KP": ("شمالی کوریا", "پیانگ یانگ"),
    "OM": ("عمان", "مسقط"),
    "PK": ("پاکستان", "اسلام آباد"),
    "PH": ("فلپائن", "منیلا"),
    "PS": ("فلسطین", "رام اللہ"),
    "QA": ("قطر", "دوحہ"),
    "SA": ("سعودی عرب", "ریاض"),
    "SG": ("سنگاپور", "سنگاپور"),
    "KR": ("جنوبی کوریا", "سیول"),
    "LK": ("سری لنکا", "سری جے وردھنے پورہ کوٹے"),
    "SY": ("شام", "دمشق"),
    "TW": ("تائیوان", "تائی پے"),
    "TJ": ("تاجکستان", "دوشنبے"),
    "TH": ("تھائی لینڈ", "بنکاک"),
    "TL": ("مشرقی تیمور", "دیلی"),
    "TR": ("ترکی", "انقرہ"),
    "TM": ("ترکمانستان", "عشق آباد"),
    "AE": ("متحدہ عرب امارات", "ابوظہبی"),
    "UZ": ("ازبکستان", "تاشقند"),
    "VN": ("ویتنام", "ہنوئی"),
    "YE": ("یمن", "صنعا"),
    "AL": ("البانیہ", "تیرانا"),
    "AD": ("انڈورا", "انڈورا لا ویلا"),
    "AT": ("آسٹریا", "ویانا"),
    "BY": ("بیلاروس", "منسک"),
    "BE": ("بیلجیم", "برسلز"),
    "BA": ("بوسنیا و ہرزیگووینا", "سراژیوو"),
    "BG": ("بلغاریہ", "صوفیہ"),
    "HR": ("کروشیا", "زغرب"),
    "CZ": ("چیک جمہوریہ", "پراگ"),
    "DK": ("ڈنمارک", "کوپن ہیگن"),
    "EE": ("اسٹونیا", "تالین"),
    "FI": ("فن لینڈ", "ہلسنکی"),
    "FR": ("فرانس", "پیرس"),
    "DE": ("جرمنی", "برلن"),
    "GR": ("یونان", "ایتھنز"),
    "HU": ("ہنگری", "بوداپیست"),
    "IS": ("آئس لینڈ", "ریکیاوک"),
    "IE": ("آئرلینڈ", "ڈبلن"),
    "IT": ("اٹلی", "روم"),
    "XK": ("کوسوو", "پریشتینا"),
    "LV": ("لٹویا", "ریگا"),
    "LI": ("لیختینستائن", "فادوز"),
    "LT": ("لتھوانیا", "ولنیئس"),
    "LU": ("لکسمبرگ", "لکسمبرگ"),
    "MT": ("مالٹا", "ویلیٹا"),
    "MD": ("مالدووا", "کشیناؤ"),
    "MC": ("موناکو", "موناکو"),
    "ME": ("مونٹینیگرو", "پوڈگوریتسا"),
    "NL": ("نیدرلینڈز", "ایمسٹرڈیم"),
    "MK": ("شمالی مقدونیہ", "سکوپیے"),
    "NO": ("ناروے", "اوسلو"),
    "PL": ("پولینڈ", "وارسا"),
    "PT": ("پرتگال", "لزبن"),
    "RO": ("رومانیہ", "بخارسٹ"),
    "RU": ("روس", "ماسکو"),
    "SM": ("سان مارینو", "سان مارینو"),
    "RS": ("سربیا", "بلغراد"),
    "SK": ("سلوواکیہ", "براتیسلاوا"),
    "SI": ("سلووینیا", "لیوبلیانا"),
    "ES": ("اسپین", "میڈرڈ"),
    "SE": ("سویڈن", "اسٹاک ہوم"),
    "CH": ("سوئٹزرلینڈ", "برن"),
    "UA": ("یوکرین", "کیئف"),
    "GB": ("برطانیہ", "لندن"),
    "VA": ("ویٹیکن سٹی", "ویٹیکن سٹی"),
    "AG": ("اینٹیگوا و باربوڈا", "سینٹ جانز"),
    "BS": ("بہاماس", "ناساؤ"),
    "BB": ("بارباڈوس", "برج ٹاؤن"),
    "BZ": ("بیلیز", "بیلموپان"),
    "CA": ("کینیڈا", "اوٹاوا"),
    "CR": ("کوسٹاریکا", "سان ہوزے"),
    "CU": ("کیوبا", "ہوانا"),
    "DM": ("ڈومینیکا", "روزو"),
    "DO": ("ڈومینیکن جمہوریہ", "سانتو ڈومنگو"),
    "SV": ("ایل سلواڈور", "سان سلواڈور"),
    "GD": ("گریناڈا", "سینٹ جارجز"),
    "GT": ("گوئٹے مالا", "گوئٹے مالا سٹی"),
    "HT": ("ہیٹی", "پورٹ او پرنس"),
    "HN": ("ہونڈوراس", "ٹیگوسیگالپا"),
    "JM": ("جمیکا", "کنگسٹن"),
    "MX": ("میکسیکو", "میکسیکو سٹی"),
    "NI": ("نکاراگوا", "ماناگوا"),
    "PA": ("پاناما", "پاناما سٹی"),
    "KN": ("سینٹ کٹس و نیوس", "باستیر"),
    "LC": ("سینٹ لوسیا", "کاستری"),
    "VC": ("سینٹ ونسنٹ و گریناڈائنز", "کنگز ٹاؤن"),
    "TT": ("ٹرینیڈاڈ و ٹوباگو", "پورٹ آف اسپین"),
    "US": ("ریاستہائے متحدہ امریکہ", "واشنگٹن ڈی سی"),
    "AU": ("آسٹریلیا", "کینبرا"),
    "FJ": ("فجی", "سووا"),
    "KI": ("کریباتی", "جنوبی تاراوا"),
    "MH": ("مارشل جزائر", "ماجورو"),
    "FM": ("مائیکرونیشیا", "پالیکیر"),
    "NR": ("ناورو", "یارین"),
    "NZ": ("نیوزی لینڈ", "ویلنگٹن"),
    "PW": ("پلاؤ", "نگیرولمڈ"),
    "PG": ("پاپوا نیو گنی", "پورٹ مورسبی"),
    "WS": ("ساموا", "آپیا"),
    "SB": ("سولومن جزائر", "ہونیارا"),
    "TO": ("ٹونگا", "نوکوالوفا"),
    "TV": ("ٹوالو", "فونافوتی"),
    "VU": ("وانواتو", "پورٹ ولا"),
    "AR": ("ارجنٹائن", "بیونس آئرس"),
    "BO": ("بولیویا", "سکرے"),
    "BR": ("برازیل", "براسیلیا"),
    "CL": ("چلی", "سینٹیاگو"),
    "CO": ("کولمبیا", "بوگوتا"),
    "EC": ("ایکواڈور", "کیٹو"),
    "GY": ("گیانا", "جارج ٹاؤن"),
    "PY": ("پیراگوئے", "اسونسیون"),
    "PE": ("پیرو", "لیما"),
    "SR": ("سرینام", "پاراماریبو"),
    "UY": ("یوراگوئے", "مونتیویدیو"),
    "VE": ("وینزویلا", "کاراکاس"),
}

RIVERS: dict[str, str] = {
    "nile": "دریائے نیل",
    "amazon": "دریائے ایمیزون",
    "yangtze": "دریائے یانگسی",
    "mississippi": "دریائے مسیسپی",
    "yenisei": "دریائے یینیسی",
    "yellow-river": "زرد دریا",
    "ob": "دریائے اوب",
    "congo": "دریائے کانگو",
    "lena": "دریائے لینا",
    "niger": "دریائے نائجر",
    "mekong": "دریائے میکانگ",
    "missouri": "دریائے میسوری",
    "volga": "دریائے وولگا",
    "zambezi": "دریائے زیمبیزی",
    "ganges": "دریائے گنگا",
    "indus": "دریائے سندھ",
    "murray": "دریائے مرے",
    "euphrates": "دریائے فرات",
    "tigris": "دریائے دجلہ",
    "rhine": "دریائے رائن",
    "danube": "دریائے ڈینیوب",
    "colorado": "دریائے کولوراڈو",
    "columbia": "دریائے کولمبیا",
    "irrawaddy": "دریائے اراوادی",
    "orange": "دریائے اورنج",
    "parana": "دریائے پارانا",
    "amur": "دریائے آمور",
    "dnieper": "دریائے ڈینیپر",
    "senegal-river": "دریائے سینیگال",
    "orinoco": "دریائے اورینوکو",
    "sao-francisco": "دریائے ساؤ فرانسسکو",
    "tocantins": "دریائے ٹوکانٹینس",
}

MOUNTAINS: dict[str, str] = {
    "himalayas": "سلسلہ کوہ ہمالیہ",
    "andes": "سلسلہ کوہ اینڈیز",
    "rockies": "راکی پہاڑ",
    "alps": "سلسلہ کوہ الپس",
    "great-dividing-range": "عظیم تقسیمی سلسلہ",
    "kunlun": "سلسلہ کوہ کنلون",
    "tian-shan": "سلسلہ کوہ تیان شان",
    "altai": "سلسلہ کوہ التائی",
    "caucasus": "سلسلہ کوہ قفقاز",
    "pyrenees": "سلسلہ کوہ پیرینیز",
    "carpathians": "سلسلہ کوہ کارپیتھیئن",
    "appalachians": "سلسلہ کوہ ایپالاچیئن",
    "atlas": "سلسلہ کوہ اطلس",
    "drakensberg": "سلسلہ کوہ ڈریکنزبرگ",
    "ethiopian-highlands": "ایتھوپیائی پہاڑیاں",
    "scandinavian-mountains": "اسکینڈینیویائی پہاڑ",
    "hindu-kush": "سلسلہ کوہ ہندوکش",
    "karakoram": "سلسلہ کوہ قراقرم",
    "pamir": "سلسلہ کوہ پامیر",
    "sierra-nevada-us": "سیئرا نیواڈا",
    "southern-alps": "جنوبی الپس",
    "zagros": "سلسلہ کوہ زاگرس",
    "eastern-rift-highlands": "مشرقی شگافی پہاڑیاں",
}

SEAS: dict[str, str] = {
    "pacific": "بحر الکاہل",
    "atlantic": "بحر اوقیانوس",
    "indian": "بحر ہند",
    "southern": "بحر جنوبی",
    "arctic": "بحر منجمد شمالی",
    "mediterranean": "بحیرہ روم",
    "caribbean": "بحیرہ کیریبیئن",
    "south-china": "بحیرہ جنوبی چین",
    "bering": "بحیرہ بیرنگ",
    "gulf-of-mexico": "خلیج میکسیکو",
    "north-sea": "بحیرہ شمال",
    "red-sea": "بحیرہ احمر",
    "black-sea": "بحیرہ اسود",
    "caspian-sea": "بحیرہ قزوین",
    "persian-gulf": "خلیج فارس",
    "east-china": "بحیرہ مشرقی چین",
    "bay-of-bengal": "خلیج بنگال",
    "arabian-sea": "بحیرہ عرب",
    "coral-sea": "بحیرہ مرجان",
    "tasman-sea": "بحیرہ تسمان",
}


def insert_after(obj: dict, anchors: list[str], key: str, value: str) -> dict:
    """Return a new dict with (key, value) inserted immediately after the first present anchor.

    `anchors` is tried in order; the column is inserted after the first one that exists. If `key`
    already exists it is removed first and re-inserted so the column sits beside its sibling. If no
    anchor is present, the key is appended at the end.
    """
    anchor = next((a for a in anchors if a in obj), None)
    out: dict = {}
    for existing_key, existing_value in obj.items():
        if existing_key == key:
            continue  # drop any prior copy; re-added at the anchor
        out[existing_key] = existing_value
        if existing_key == anchor:
            out[key] = value
    if anchor is None:
        out[key] = value
    return out


def process(filename: str, names: dict, has_capital: bool) -> None:
    path = RES / filename
    data = json.loads(path.read_text(encoding="utf-8"))
    missing = [o["id"] for o in data if o["id"] not in names]
    if missing:
        raise SystemExit(f"{filename}: no Urdu mapping for ids: {missing}")
    new_data = []
    for obj in data:
        oid = obj["id"]
        entry = names[oid]
        name_ur = entry[0] if has_capital else entry
        obj = insert_after(obj, ["name_ar", "name"], "name_ur", name_ur)
        if has_capital:
            obj = insert_after(obj, ["capital_ar", "capital"], "capital_ur", entry[1])
        new_data.append(obj)
    path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"{filename}: wrote name_ur for {len(new_data)} entities"
        + (" + capital_ur" if has_capital else "")
    )


def main() -> None:
    process("countries.json", COUNTRIES, has_capital=True)
    process("rivers.json", RIVERS, has_capital=False)
    process("mountains.json", MOUNTAINS, has_capital=False)
    process("seas.json", SEAS, has_capital=False)


if __name__ == "__main__":
    main()
