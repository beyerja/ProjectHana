#!/usr/bin/env python3
"""One-shot helper: inject standard Japanese exonyms (name_ja / capital_ja) into the source geo
JSONs for story 003 (Japanese content).

Reads the curated id -> Japanese maps below and writes `name_ja` (all entities) and `capital_ja`
(countries only) into each object in countries.json / rivers.json / mountains.json / seas.json,
placed immediately after the base `name` / `capital` key so the new columns sit beside their
siblings. Idempotent: re-running overwrites the ja columns with the curated values. Preserves all
other keys and their order, and round-trips JSON with ensure_ascii=False + 2-space indent to match
the existing files.

The translations are standard, well-established Japanese exonyms in native script (kanji/kana). No
blank or English-placeholder values — the strict completeness gate fails on any missing/blank value.
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RES = REPO_ROOT / "Hanahuac" / "Resources"

# id -> (name_ja, capital_ja)
COUNTRIES: dict[str, tuple[str, str]] = {
    "DZ": ("アルジェリア", "アルジェ"),
    "AO": ("アンゴラ", "ルアンダ"),
    "BJ": ("ベナン", "ポルトノボ"),
    "BW": ("ボツワナ", "ハボローネ"),
    "BF": ("ブルキナファソ", "ワガドゥグー"),
    "BI": ("ブルンジ", "ギテガ"),
    "CV": ("カーボベルデ", "プライア"),
    "CM": ("カメルーン", "ヤウンデ"),
    "CF": ("中央アフリカ共和国", "バンギ"),
    "TD": ("チャド", "ンジャメナ"),
    "KM": ("コモロ", "モロニ"),
    "CD": ("コンゴ民主共和国", "キンシャサ"),
    "DJ": ("ジブチ", "ジブチ市"),
    "EG": ("エジプト", "カイロ"),
    "GQ": ("赤道ギニア", "マラボ"),
    "ER": ("エリトリア", "アスマラ"),
    "SZ": ("エスワティニ", "ムババーネ"),
    "ET": ("エチオピア", "アディスアベバ"),
    "GA": ("ガボン", "リーブルビル"),
    "GM": ("ガンビア", "バンジュール"),
    "GH": ("ガーナ", "アクラ"),
    "GN": ("ギニア", "コナクリ"),
    "GW": ("ギニアビサウ", "ビサウ"),
    "CI": ("コートジボワール", "ヤムスクロ"),
    "KE": ("ケニア", "ナイロビ"),
    "LS": ("レソト", "マセル"),
    "LR": ("リベリア", "モンロビア"),
    "LY": ("リビア", "トリポリ"),
    "MG": ("マダガスカル", "アンタナナリボ"),
    "MW": ("マラウイ", "リロングウェ"),
    "ML": ("マリ", "バマコ"),
    "MR": ("モーリタニア", "ヌアクショット"),
    "MU": ("モーリシャス", "ポートルイス"),
    "MA": ("モロッコ", "ラバト"),
    "MZ": ("モザンビーク", "マプト"),
    "NA": ("ナミビア", "ウィントフック"),
    "NE": ("ニジェール", "ニアメ"),
    "NG": ("ナイジェリア", "アブジャ"),
    "CG": ("コンゴ共和国", "ブラザビル"),
    "RW": ("ルワンダ", "キガリ"),
    "ST": ("サントメ・プリンシペ", "サントメ"),
    "SN": ("セネガル", "ダカール"),
    "SC": ("セーシェル", "ビクトリア"),
    "SL": ("シエラレオネ", "フリータウン"),
    "SO": ("ソマリア", "モガディシュ"),
    "ZA": ("南アフリカ", "プレトリア"),
    "SS": ("南スーダン", "ジュバ"),
    "SD": ("スーダン", "ハルツーム"),
    "TZ": ("タンザニア", "ドドマ"),
    "TG": ("トーゴ", "ロメ"),
    "TN": ("チュニジア", "チュニス"),
    "UG": ("ウガンダ", "カンパラ"),
    "ZM": ("ザンビア", "ルサカ"),
    "ZW": ("ジンバブエ", "ハラレ"),
    "AF": ("アフガニスタン", "カブール"),
    "AM": ("アルメニア", "エレバン"),
    "AZ": ("アゼルバイジャン", "バクー"),
    "BH": ("バーレーン", "マナーマ"),
    "BD": ("バングラデシュ", "ダッカ"),
    "BT": ("ブータン", "ティンプー"),
    "BN": ("ブルネイ", "バンダルスリブガワン"),
    "KH": ("カンボジア", "プノンペン"),
    "CN": ("中国", "北京"),
    "CY": ("キプロス", "ニコシア"),
    "GE": ("ジョージア", "トビリシ"),
    "IN": ("インド", "ニューデリー"),
    "ID": ("インドネシア", "ジャカルタ"),
    "IR": ("イラン", "テヘラン"),
    "IQ": ("イラク", "バグダッド"),
    "IL": ("イスラエル", "エルサレム"),
    "JP": ("日本", "東京"),
    "JO": ("ヨルダン", "アンマン"),
    "KZ": ("カザフスタン", "アスタナ"),
    "KW": ("クウェート", "クウェート市"),
    "KG": ("キルギス", "ビシュケク"),
    "LA": ("ラオス", "ビエンチャン"),
    "LB": ("レバノン", "ベイルート"),
    "MY": ("マレーシア", "クアラルンプール"),
    "MV": ("モルディブ", "マレ"),
    "MN": ("モンゴル", "ウランバートル"),
    "MM": ("ミャンマー", "ネピドー"),
    "NP": ("ネパール", "カトマンズ"),
    "KP": ("北朝鮮", "平壌"),
    "OM": ("オマーン", "マスカット"),
    "PK": ("パキスタン", "イスラマバード"),
    "PH": ("フィリピン", "マニラ"),
    "PS": ("パレスチナ", "ラマッラー"),
    "QA": ("カタール", "ドーハ"),
    "SA": ("サウジアラビア", "リヤド"),
    "SG": ("シンガポール", "シンガポール"),
    "KR": ("韓国", "ソウル"),
    "LK": ("スリランカ", "スリジャヤワルダナプラコッテ"),
    "SY": ("シリア", "ダマスカス"),
    "TW": ("台湾", "台北"),
    "TJ": ("タジキスタン", "ドゥシャンベ"),
    "TH": ("タイ", "バンコク"),
    "TL": ("東ティモール", "ディリ"),
    "TR": ("トルコ", "アンカラ"),
    "TM": ("トルクメニスタン", "アシガバート"),
    "AE": ("アラブ首長国連邦", "アブダビ"),
    "UZ": ("ウズベキスタン", "タシケント"),
    "VN": ("ベトナム", "ハノイ"),
    "YE": ("イエメン", "サナア"),
    "AL": ("アルバニア", "ティラナ"),
    "AD": ("アンドラ", "アンドラ・ラ・ベリャ"),
    "AT": ("オーストリア", "ウィーン"),
    "BY": ("ベラルーシ", "ミンスク"),
    "BE": ("ベルギー", "ブリュッセル"),
    "BA": ("ボスニア・ヘルツェゴビナ", "サラエボ"),
    "BG": ("ブルガリア", "ソフィア"),
    "HR": ("クロアチア", "ザグレブ"),
    "CZ": ("チェコ", "プラハ"),
    "DK": ("デンマーク", "コペンハーゲン"),
    "EE": ("エストニア", "タリン"),
    "FI": ("フィンランド", "ヘルシンキ"),
    "FR": ("フランス", "パリ"),
    "DE": ("ドイツ", "ベルリン"),
    "GR": ("ギリシャ", "アテネ"),
    "HU": ("ハンガリー", "ブダペスト"),
    "IS": ("アイスランド", "レイキャビク"),
    "IE": ("アイルランド", "ダブリン"),
    "IT": ("イタリア", "ローマ"),
    "XK": ("コソボ", "プリシュティナ"),
    "LV": ("ラトビア", "リガ"),
    "LI": ("リヒテンシュタイン", "ファドゥーツ"),
    "LT": ("リトアニア", "ビリニュス"),
    "LU": ("ルクセンブルク", "ルクセンブルク市"),
    "MT": ("マルタ", "バレッタ"),
    "MD": ("モルドバ", "キシナウ"),
    "MC": ("モナコ", "モナコ"),
    "ME": ("モンテネグロ", "ポドゴリツァ"),
    "NL": ("オランダ", "アムステルダム"),
    "MK": ("北マケドニア", "スコピエ"),
    "NO": ("ノルウェー", "オスロ"),
    "PL": ("ポーランド", "ワルシャワ"),
    "PT": ("ポルトガル", "リスボン"),
    "RO": ("ルーマニア", "ブカレスト"),
    "RU": ("ロシア", "モスクワ"),
    "SM": ("サンマリノ", "サンマリノ"),
    "RS": ("セルビア", "ベオグラード"),
    "SK": ("スロバキア", "ブラチスラバ"),
    "SI": ("スロベニア", "リュブリャナ"),
    "ES": ("スペイン", "マドリード"),
    "SE": ("スウェーデン", "ストックホルム"),
    "CH": ("スイス", "ベルン"),
    "UA": ("ウクライナ", "キーウ"),
    "GB": ("イギリス", "ロンドン"),
    "VA": ("バチカン市国", "バチカン"),
    "AG": ("アンティグア・バーブーダ", "セントジョンズ"),
    "BS": ("バハマ", "ナッソー"),
    "BB": ("バルバドス", "ブリッジタウン"),
    "BZ": ("ベリーズ", "ベルモパン"),
    "CA": ("カナダ", "オタワ"),
    "CR": ("コスタリカ", "サンホセ"),
    "CU": ("キューバ", "ハバナ"),
    "DM": ("ドミニカ国", "ロゾー"),
    "DO": ("ドミニカ共和国", "サントドミンゴ"),
    "SV": ("エルサルバドル", "サンサルバドル"),
    "GD": ("グレナダ", "セントジョージズ"),
    "GT": ("グアテマラ", "グアテマラシティ"),
    "HT": ("ハイチ", "ポルトープランス"),
    "HN": ("ホンジュラス", "テグシガルパ"),
    "JM": ("ジャマイカ", "キングストン"),
    "MX": ("メキシコ", "メキシコシティ"),
    "NI": ("ニカラグア", "マナグア"),
    "PA": ("パナマ", "パナマシティ"),
    "KN": ("セントクリストファー・ネイビス", "バセテール"),
    "LC": ("セントルシア", "カストリーズ"),
    "VC": ("セントビンセント・グレナディーン", "キングスタウン"),
    "TT": ("トリニダード・トバゴ", "ポートオブスペイン"),
    "US": ("アメリカ合衆国", "ワシントンD.C."),
    "AU": ("オーストラリア", "キャンベラ"),
    "FJ": ("フィジー", "スバ"),
    "KI": ("キリバス", "サウスタラワ"),
    "MH": ("マーシャル諸島", "マジュロ"),
    "FM": ("ミクロネシア連邦", "パリキール"),
    "NR": ("ナウル", "ヤレン"),
    "NZ": ("ニュージーランド", "ウェリントン"),
    "PW": ("パラオ", "ンゲルルムッド"),
    "PG": ("パプアニューギニア", "ポートモレスビー"),
    "WS": ("サモア", "アピア"),
    "SB": ("ソロモン諸島", "ホニアラ"),
    "TO": ("トンガ", "ヌクアロファ"),
    "TV": ("ツバル", "フナフティ"),
    "VU": ("バヌアツ", "ポートビラ"),
    "AR": ("アルゼンチン", "ブエノスアイレス"),
    "BO": ("ボリビア", "スクレ"),
    "BR": ("ブラジル", "ブラジリア"),
    "CL": ("チリ", "サンティアゴ"),
    "CO": ("コロンビア", "ボゴタ"),
    "EC": ("エクアドル", "キト"),
    "GY": ("ガイアナ", "ジョージタウン"),
    "PY": ("パラグアイ", "アスンシオン"),
    "PE": ("ペルー", "リマ"),
    "SR": ("スリナム", "パラマリボ"),
    "UY": ("ウルグアイ", "モンテビデオ"),
    "VE": ("ベネズエラ", "カラカス"),
}

RIVERS: dict[str, str] = {
    "nile": "ナイル川",
    "amazon": "アマゾン川",
    "yangtze": "長江",
    "mississippi": "ミシシッピ川",
    "yenisei": "エニセイ川",
    "yellow-river": "黄河",
    "ob": "オビ川",
    "congo": "コンゴ川",
    "lena": "レナ川",
    "niger": "ニジェール川",
    "mekong": "メコン川",
    "missouri": "ミズーリ川",
    "volga": "ヴォルガ川",
    "zambezi": "ザンベジ川",
    "ganges": "ガンジス川",
    "indus": "インダス川",
    "murray": "マレー川",
    "euphrates": "ユーフラテス川",
    "tigris": "ティグリス川",
    "rhine": "ライン川",
    "danube": "ドナウ川",
    "colorado": "コロラド川",
    "columbia": "コロンビア川",
    "irrawaddy": "イラワジ川",
    "orange": "オレンジ川",
    "parana": "パラナ川",
    "amur": "アムール川",
    "dnieper": "ドニエプル川",
    "senegal-river": "セネガル川",
    "orinoco": "オリノコ川",
    "sao-francisco": "サンフランシスコ川",
    "tocantins": "トカンティンス川",
}

MOUNTAINS: dict[str, str] = {
    "himalayas": "ヒマラヤ山脈",
    "andes": "アンデス山脈",
    "rockies": "ロッキー山脈",
    "alps": "アルプス山脈",
    "great-dividing-range": "グレートディバイディング山脈",
    "kunlun": "崑崙山脈",
    "tian-shan": "天山山脈",
    "altai": "アルタイ山脈",
    "caucasus": "カフカス山脈",
    "pyrenees": "ピレネー山脈",
    "carpathians": "カルパティア山脈",
    "appalachians": "アパラチア山脈",
    "atlas": "アトラス山脈",
    "drakensberg": "ドラケンスバーグ山脈",
    "ethiopian-highlands": "エチオピア高原",
    "scandinavian-mountains": "スカンディナヴィア山脈",
    "hindu-kush": "ヒンドゥークシュ山脈",
    "karakoram": "カラコルム山脈",
    "pamir": "パミール高原",
    "sierra-nevada-us": "シエラネバダ山脈",
    "southern-alps": "サザンアルプス",
    "zagros": "ザグロス山脈",
    "eastern-rift-highlands": "東アフリカ地溝帯高地",
}

SEAS: dict[str, str] = {
    "pacific": "太平洋",
    "atlantic": "大西洋",
    "indian": "インド洋",
    "southern": "南極海",
    "arctic": "北極海",
    "mediterranean": "地中海",
    "caribbean": "カリブ海",
    "south-china": "南シナ海",
    "bering": "ベーリング海",
    "gulf-of-mexico": "メキシコ湾",
    "north-sea": "北海",
    "red-sea": "紅海",
    "black-sea": "黒海",
    "caspian-sea": "カスピ海",
    "persian-gulf": "ペルシア湾",
    "east-china": "東シナ海",
    "bay-of-bengal": "ベンガル湾",
    "arabian-sea": "アラビア海",
    "coral-sea": "サンゴ海",
    "tasman-sea": "タスマン海",
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
        raise SystemExit(f"{filename}: no Japanese mapping for ids: {missing}")
    new_data = []
    for obj in data:
        oid = obj["id"]
        entry = names[oid]
        name_ja = entry[0] if has_capital else entry
        obj = insert_after(obj, "name", "name_ja", name_ja)
        if has_capital:
            obj = insert_after(obj, "capital", "capital_ja", entry[1])
        new_data.append(obj)
    path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"{filename}: wrote name_ja for {len(new_data)} entities"
        + (" + capital_ja" if has_capital else "")
    )


def main() -> None:
    process("countries.json", COUNTRIES, has_capital=True)
    process("rivers.json", RIVERS, has_capital=False)
    process("mountains.json", MOUNTAINS, has_capital=False)
    process("seas.json", SEAS, has_capital=False)


if __name__ == "__main__":
    main()
