#!/usr/bin/env python3
"""One-shot helper: inject standard Simplified Chinese exonyms (name_zh_hans / capital_zh_hans) into
the source geo JSONs for story 004 (Simplified Chinese content).

Reads the curated id -> Simplified Chinese maps below and writes `name_zh_hans` (all entities) and
`capital_zh_hans` (countries only) into each object in countries.json / rivers.json / mountains.json /
seas.json, placed immediately after the base `name` / `capital` key so the new columns sit beside
their siblings. Idempotent: re-running overwrites the zh_hans columns with the curated values.
Preserves all other keys and their order, and round-trips JSON with ensure_ascii=False + 2-space
indent to match the existing files.

The translations are standard, well-established Simplified Chinese exonyms (简体字). No blank or
English-placeholder values — the strict completeness gate fails on any missing/blank value.
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RES = REPO_ROOT / "Hanahuac" / "Resources"

# id -> (name_zh_hans, capital_zh_hans)
COUNTRIES: dict[str, tuple[str, str]] = {
    "DZ": ("阿尔及利亚", "阿尔及尔"),
    "AO": ("安哥拉", "罗安达"),
    "BJ": ("贝宁", "波多诺伏"),
    "BW": ("博茨瓦纳", "哈博罗内"),
    "BF": ("布基纳法索", "瓦加杜古"),
    "BI": ("布隆迪", "基特加"),
    "CV": ("佛得角", "普拉亚"),
    "CM": ("喀麦隆", "雅温得"),
    "CF": ("中非共和国", "班吉"),
    "TD": ("乍得", "恩贾梅纳"),
    "KM": ("科摩罗", "莫罗尼"),
    "CD": ("刚果民主共和国", "金沙萨"),
    "DJ": ("吉布提", "吉布提市"),
    "EG": ("埃及", "开罗"),
    "GQ": ("赤道几内亚", "马拉博"),
    "ER": ("厄立特里亚", "阿斯马拉"),
    "SZ": ("斯威士兰", "姆巴巴纳"),
    "ET": ("埃塞俄比亚", "亚的斯亚贝巴"),
    "GA": ("加蓬", "利伯维尔"),
    "GM": ("冈比亚", "班珠尔"),
    "GH": ("加纳", "阿克拉"),
    "GN": ("几内亚", "科纳克里"),
    "GW": ("几内亚比绍", "比绍"),
    "CI": ("科特迪瓦", "亚穆苏克罗"),
    "KE": ("肯尼亚", "内罗毕"),
    "LS": ("莱索托", "马塞卢"),
    "LR": ("利比里亚", "蒙罗维亚"),
    "LY": ("利比亚", "的黎波里"),
    "MG": ("马达加斯加", "塔那那利佛"),
    "MW": ("马拉维", "利隆圭"),
    "ML": ("马里", "巴马科"),
    "MR": ("毛里塔尼亚", "努瓦克肖特"),
    "MU": ("毛里求斯", "路易港"),
    "MA": ("摩洛哥", "拉巴特"),
    "MZ": ("莫桑比克", "马普托"),
    "NA": ("纳米比亚", "温得和克"),
    "NE": ("尼日尔", "尼亚美"),
    "NG": ("尼日利亚", "阿布贾"),
    "CG": ("刚果共和国", "布拉柴维尔"),
    "RW": ("卢旺达", "基加利"),
    "ST": ("圣多美和普林西比", "圣多美"),
    "SN": ("塞内加尔", "达喀尔"),
    "SC": ("塞舌尔", "维多利亚"),
    "SL": ("塞拉利昂", "弗里敦"),
    "SO": ("索马里", "摩加迪沙"),
    "ZA": ("南非", "比勒陀利亚"),
    "SS": ("南苏丹", "朱巴"),
    "SD": ("苏丹", "喀土穆"),
    "TZ": ("坦桑尼亚", "多多马"),
    "TG": ("多哥", "洛美"),
    "TN": ("突尼斯", "突尼斯市"),
    "UG": ("乌干达", "坎帕拉"),
    "ZM": ("赞比亚", "卢萨卡"),
    "ZW": ("津巴布韦", "哈拉雷"),
    "AF": ("阿富汗", "喀布尔"),
    "AM": ("亚美尼亚", "埃里温"),
    "AZ": ("阿塞拜疆", "巴库"),
    "BH": ("巴林", "麦纳麦"),
    "BD": ("孟加拉国", "达卡"),
    "BT": ("不丹", "廷布"),
    "BN": ("文莱", "斯里巴加湾市"),
    "KH": ("柬埔寨", "金边"),
    "CN": ("中国", "北京"),
    "CY": ("塞浦路斯", "尼科西亚"),
    "GE": ("格鲁吉亚", "第比利斯"),
    "IN": ("印度", "新德里"),
    "ID": ("印度尼西亚", "雅加达"),
    "IR": ("伊朗", "德黑兰"),
    "IQ": ("伊拉克", "巴格达"),
    "IL": ("以色列", "耶路撒冷"),
    "JP": ("日本", "东京"),
    "JO": ("约旦", "安曼"),
    "KZ": ("哈萨克斯坦", "阿斯塔纳"),
    "KW": ("科威特", "科威特城"),
    "KG": ("吉尔吉斯斯坦", "比什凯克"),
    "LA": ("老挝", "万象"),
    "LB": ("黎巴嫩", "贝鲁特"),
    "MY": ("马来西亚", "吉隆坡"),
    "MV": ("马尔代夫", "马累"),
    "MN": ("蒙古", "乌兰巴托"),
    "MM": ("缅甸", "内比都"),
    "NP": ("尼泊尔", "加德满都"),
    "KP": ("朝鲜", "平壤"),
    "OM": ("阿曼", "马斯喀特"),
    "PK": ("巴基斯坦", "伊斯兰堡"),
    "PH": ("菲律宾", "马尼拉"),
    "PS": ("巴勒斯坦", "拉马拉"),
    "QA": ("卡塔尔", "多哈"),
    "SA": ("沙特阿拉伯", "利雅得"),
    "SG": ("新加坡", "新加坡"),
    "KR": ("韩国", "首尔"),
    "LK": ("斯里兰卡", "斯里贾亚瓦德纳普拉科特"),
    "SY": ("叙利亚", "大马士革"),
    "TW": ("台湾", "台北"),
    "TJ": ("塔吉克斯坦", "杜尚别"),
    "TH": ("泰国", "曼谷"),
    "TL": ("东帝汶", "帝力"),
    "TR": ("土耳其", "安卡拉"),
    "TM": ("土库曼斯坦", "阿什哈巴德"),
    "AE": ("阿拉伯联合酋长国", "阿布扎比"),
    "UZ": ("乌兹别克斯坦", "塔什干"),
    "VN": ("越南", "河内"),
    "YE": ("也门", "萨那"),
    "AL": ("阿尔巴尼亚", "地拉那"),
    "AD": ("安道尔", "安道尔城"),
    "AT": ("奥地利", "维也纳"),
    "BY": ("白俄罗斯", "明斯克"),
    "BE": ("比利时", "布鲁塞尔"),
    "BA": ("波斯尼亚和黑塞哥维那", "萨拉热窝"),
    "BG": ("保加利亚", "索非亚"),
    "HR": ("克罗地亚", "萨格勒布"),
    "CZ": ("捷克", "布拉格"),
    "DK": ("丹麦", "哥本哈根"),
    "EE": ("爱沙尼亚", "塔林"),
    "FI": ("芬兰", "赫尔辛基"),
    "FR": ("法国", "巴黎"),
    "DE": ("德国", "柏林"),
    "GR": ("希腊", "雅典"),
    "HU": ("匈牙利", "布达佩斯"),
    "IS": ("冰岛", "雷克雅未克"),
    "IE": ("爱尔兰", "都柏林"),
    "IT": ("意大利", "罗马"),
    "XK": ("科索沃", "普里什蒂纳"),
    "LV": ("拉脱维亚", "里加"),
    "LI": ("列支敦士登", "瓦杜兹"),
    "LT": ("立陶宛", "维尔纽斯"),
    "LU": ("卢森堡", "卢森堡市"),
    "MT": ("马耳他", "瓦莱塔"),
    "MD": ("摩尔多瓦", "基希讷乌"),
    "MC": ("摩纳哥", "摩纳哥"),
    "ME": ("黑山", "波德戈里察"),
    "NL": ("荷兰", "阿姆斯特丹"),
    "MK": ("北马其顿", "斯科普里"),
    "NO": ("挪威", "奥斯陆"),
    "PL": ("波兰", "华沙"),
    "PT": ("葡萄牙", "里斯本"),
    "RO": ("罗马尼亚", "布加勒斯特"),
    "RU": ("俄罗斯", "莫斯科"),
    "SM": ("圣马力诺", "圣马力诺"),
    "RS": ("塞尔维亚", "贝尔格莱德"),
    "SK": ("斯洛伐克", "布拉迪斯拉发"),
    "SI": ("斯洛文尼亚", "卢布尔雅那"),
    "ES": ("西班牙", "马德里"),
    "SE": ("瑞典", "斯德哥尔摩"),
    "CH": ("瑞士", "伯尔尼"),
    "UA": ("乌克兰", "基辅"),
    "GB": ("英国", "伦敦"),
    "VA": ("梵蒂冈", "梵蒂冈城"),
    "AG": ("安提瓜和巴布达", "圣约翰斯"),
    "BS": ("巴哈马", "拿骚"),
    "BB": ("巴巴多斯", "布里奇敦"),
    "BZ": ("伯利兹", "贝尔莫潘"),
    "CA": ("加拿大", "渥太华"),
    "CR": ("哥斯达黎加", "圣何塞"),
    "CU": ("古巴", "哈瓦那"),
    "DM": ("多米尼克", "罗索"),
    "DO": ("多米尼加共和国", "圣多明各"),
    "SV": ("萨尔瓦多", "圣萨尔瓦多"),
    "GD": ("格林纳达", "圣乔治"),
    "GT": ("危地马拉", "危地马拉城"),
    "HT": ("海地", "太子港"),
    "HN": ("洪都拉斯", "特古西加尔巴"),
    "JM": ("牙买加", "金斯敦"),
    "MX": ("墨西哥", "墨西哥城"),
    "NI": ("尼加拉瓜", "马那瓜"),
    "PA": ("巴拿马", "巴拿马城"),
    "KN": ("圣基茨和尼维斯", "巴斯特尔"),
    "LC": ("圣卢西亚", "卡斯特里"),
    "VC": ("圣文森特和格林纳丁斯", "金斯敦"),
    "TT": ("特立尼达和多巴哥", "西班牙港"),
    "US": ("美国", "华盛顿"),
    "AU": ("澳大利亚", "堪培拉"),
    "FJ": ("斐济", "苏瓦"),
    "KI": ("基里巴斯", "南塔拉瓦"),
    "MH": ("马绍尔群岛", "马朱罗"),
    "FM": ("密克罗尼西亚联邦", "帕利基尔"),
    "NR": ("瑙鲁", "亚伦"),
    "NZ": ("新西兰", "惠灵顿"),
    "PW": ("帕劳", "恩吉鲁尔穆德"),
    "PG": ("巴布亚新几内亚", "莫尔兹比港"),
    "WS": ("萨摩亚", "阿皮亚"),
    "SB": ("所罗门群岛", "霍尼亚拉"),
    "TO": ("汤加", "努库阿洛法"),
    "TV": ("图瓦卢", "富纳富提"),
    "VU": ("瓦努阿图", "维拉港"),
    "AR": ("阿根廷", "布宜诺斯艾利斯"),
    "BO": ("玻利维亚", "苏克雷"),
    "BR": ("巴西", "巴西利亚"),
    "CL": ("智利", "圣地亚哥"),
    "CO": ("哥伦比亚", "波哥大"),
    "EC": ("厄瓜多尔", "基多"),
    "GY": ("圭亚那", "乔治敦"),
    "PY": ("巴拉圭", "亚松森"),
    "PE": ("秘鲁", "利马"),
    "SR": ("苏里南", "帕拉马里博"),
    "UY": ("乌拉圭", "蒙得维的亚"),
    "VE": ("委内瑞拉", "加拉加斯"),
}

RIVERS: dict[str, str] = {
    "nile": "尼罗河",
    "amazon": "亚马逊河",
    "yangtze": "长江",
    "mississippi": "密西西比河",
    "yenisei": "叶尼塞河",
    "yellow-river": "黄河",
    "ob": "鄂毕河",
    "congo": "刚果河",
    "lena": "勒拿河",
    "niger": "尼日尔河",
    "mekong": "湄公河",
    "missouri": "密苏里河",
    "volga": "伏尔加河",
    "zambezi": "赞比西河",
    "ganges": "恒河",
    "indus": "印度河",
    "murray": "墨累河",
    "euphrates": "幼发拉底河",
    "tigris": "底格里斯河",
    "rhine": "莱茵河",
    "danube": "多瑙河",
    "colorado": "科罗拉多河",
    "columbia": "哥伦比亚河",
    "irrawaddy": "伊洛瓦底江",
    "orange": "奥兰治河",
    "parana": "巴拉那河",
    "amur": "黑龙江",
    "dnieper": "第聂伯河",
    "senegal-river": "塞内加尔河",
    "orinoco": "奥里诺科河",
    "sao-francisco": "圣弗朗西斯科河",
    "tocantins": "托坎廷斯河",
}

MOUNTAINS: dict[str, str] = {
    "himalayas": "喜马拉雅山脉",
    "andes": "安第斯山脉",
    "rockies": "落基山脉",
    "alps": "阿尔卑斯山脉",
    "great-dividing-range": "大分水岭",
    "kunlun": "昆仑山脉",
    "tian-shan": "天山山脉",
    "altai": "阿尔泰山脉",
    "caucasus": "高加索山脉",
    "pyrenees": "比利牛斯山脉",
    "carpathians": "喀尔巴阡山脉",
    "appalachians": "阿巴拉契亚山脉",
    "atlas": "阿特拉斯山脉",
    "drakensberg": "德拉肯斯山脉",
    "ethiopian-highlands": "埃塞俄比亚高原",
    "scandinavian-mountains": "斯堪的纳维亚山脉",
    "hindu-kush": "兴都库什山脉",
    "karakoram": "喀喇昆仑山脉",
    "pamir": "帕米尔高原",
    "sierra-nevada-us": "内华达山脉",
    "southern-alps": "南阿尔卑斯山脉",
    "zagros": "扎格罗斯山脉",
    "eastern-rift-highlands": "东非大裂谷高地",
}

SEAS: dict[str, str] = {
    "pacific": "太平洋",
    "atlantic": "大西洋",
    "indian": "印度洋",
    "southern": "南冰洋",
    "arctic": "北冰洋",
    "mediterranean": "地中海",
    "caribbean": "加勒比海",
    "south-china": "南海",
    "bering": "白令海",
    "gulf-of-mexico": "墨西哥湾",
    "north-sea": "北海",
    "red-sea": "红海",
    "black-sea": "黑海",
    "caspian-sea": "里海",
    "persian-gulf": "波斯湾",
    "east-china": "东海",
    "bay-of-bengal": "孟加拉湾",
    "arabian-sea": "阿拉伯海",
    "coral-sea": "珊瑚海",
    "tasman-sea": "塔斯曼海",
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
        raise SystemExit(f"{filename}: no Simplified Chinese mapping for ids: {missing}")
    new_data = []
    for obj in data:
        oid = obj["id"]
        entry = names[oid]
        name_zh = entry[0] if has_capital else entry
        obj = insert_after(obj, "name", "name_zh_hans", name_zh)
        if has_capital:
            obj = insert_after(obj, "capital", "capital_zh_hans", entry[1])
        new_data.append(obj)
    path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"{filename}: wrote name_zh_hans for {len(new_data)} entities"
        + (" + capital_zh_hans" if has_capital else "")
    )


def main() -> None:
    process("countries.json", COUNTRIES, has_capital=True)
    process("rivers.json", RIVERS, has_capital=False)
    process("mountains.json", MOUNTAINS, has_capital=False)
    process("seas.json", SEAS, has_capital=False)


if __name__ == "__main__":
    main()
