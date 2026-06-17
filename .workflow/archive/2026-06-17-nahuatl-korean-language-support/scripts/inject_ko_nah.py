#!/usr/bin/env python3
"""One-shot helper: inject best-effort Korean (and partial Nahuatl) names into the geographic
JSON resources, keyed by stable id. Preserves all existing keys/order; only adds name_ko/name_nah
(and capital_ko/capital_nah for countries) where a confident value exists. Re-runnable (idempotent).
Run from the worktree root. This script lives under .workflow/ and is not shipped in the app.
"""
import json
import os
from collections import OrderedDict

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
RES = os.path.join(ROOT, "Hanahuac", "Resources")

# --- Countries: id -> (name_ko, capital_ko, name_nah?, capital_nah?) ---
# Korean exonyms are well established → full coverage. Nahuatl is partial (Americas + majors).
COUNTRY = {
    # Africa
    "DZ": ("알제리", "알제"), "AO": ("앙골라", "루안다"), "BJ": ("베냉", "포르토노보"),
    "BW": ("보츠와나", "가보로네"), "BF": ("부르키나파소", "와가두구"), "BI": ("부룬디", "기테가"),
    "CV": ("카보베르데", "프라이아"), "CM": ("카메룬", "야운데"),
    "CF": ("중앙아프리카공화국", "방기"), "TD": ("차드", "은자메나"), "KM": ("코모로", "모로니"),
    "CD": ("콩고민주공화국", "킨샤사"), "DJ": ("지부티", "지부티시"), "EG": ("이집트", "카이로"),
    "GQ": ("적도기니", "말라보"), "ER": ("에리트레아", "아스마라"), "SZ": ("에스와티니", "음바바네"),
    "ET": ("에티오피아", "아디스아바바"), "GA": ("가봉", "리브르빌"), "GM": ("감비아", "반줄"),
    "GH": ("가나", "아크라"), "GN": ("기니", "코나크리"), "GW": ("기니비사우", "비사우"),
    "CI": ("코트디부아르", "야무수크로"), "KE": ("케냐", "나이로비"), "LS": ("레소토", "마세루"),
    "LR": ("라이베리아", "몬로비아"), "LY": ("리비아", "트리폴리"), "MG": ("마다가스카르", "안타나나리보"),
    "MW": ("말라위", "릴롱궤"), "ML": ("말리", "바마코"), "MR": ("모리타니", "누악쇼트"),
    "MU": ("모리셔스", "포트루이스"), "MA": ("모로코", "라바트"), "MZ": ("모잠비크", "마푸투"),
    "NA": ("나미비아", "빈트후크"), "NE": ("니제르", "니아메"), "NG": ("나이지리아", "아부자"),
    "CG": ("콩고공화국", "브라자빌"), "RW": ("르완다", "키갈리"), "ST": ("상투메프린시페", "상투메"),
    "SN": ("세네갈", "다카르"), "SC": ("세이셸", "빅토리아"), "SL": ("시에라리온", "프리타운"),
    "SO": ("소말리아", "모가디슈"), "ZA": ("남아프리카공화국", "프리토리아"), "SS": ("남수단", "주바"),
    "SD": ("수단", "하르툼"), "TZ": ("탄자니아", "도도마"), "TG": ("토고", "로메"),
    "TN": ("튀니지", "튀니스"), "UG": ("우간다", "캄팔라"), "ZM": ("잠비아", "루사카"),
    "ZW": ("짐바브웨", "하라레"),
    # Asia
    "AF": ("아프가니스탄", "카불"), "AM": ("아르메니아", "예레반"), "AZ": ("아제르바이잔", "바쿠"),
    "BH": ("바레인", "마나마"), "BD": ("방글라데시", "다카"), "BT": ("부탄", "팀부"),
    "BN": ("브루나이", "반다르스리브가완"), "KH": ("캄보디아", "프놈펜"), "CN": ("중국", "베이징"),
    "CY": ("키프로스", "니코시아"), "GE": ("조지아", "트빌리시"), "IN": ("인도", "뉴델리"),
    "ID": ("인도네시아", "자카르타"), "IR": ("이란", "테헤란"), "IQ": ("이라크", "바그다드"),
    "IL": ("이스라엘", "예루살렘"), "JP": ("일본", "도쿄"), "JO": ("요르단", "암만"),
    "KZ": ("카자흐스탄", "아스타나"), "KW": ("쿠웨이트", "쿠웨이트시티"), "KG": ("키르기스스탄", "비슈케크"),
    "LA": ("라오스", "비엔티안"), "LB": ("레바논", "베이루트"), "MY": ("말레이시아", "쿠알라룸푸르"),
    "MV": ("몰디브", "말레"), "MN": ("몽골", "울란바토르"), "MM": ("미얀마", "네피도"),
    "NP": ("네팔", "카트만두"), "KP": ("조선민주주의인민공화국", "평양"), "OM": ("오만", "무스카트"),
    "PK": ("파키스탄", "이슬라마바드"), "PH": ("필리핀", "마닐라"), "PS": ("팔레스타인", "라말라"),
    "QA": ("카타르", "도하"), "SA": ("사우디아라비아", "리야드"), "SG": ("싱가포르", "싱가포르"),
    "KR": ("대한민국", "서울"), "LK": ("스리랑카", "스리자야와르데네푸라코테"), "SY": ("시리아", "다마스쿠스"),
    "TW": ("타이완", "타이베이"), "TJ": ("타지키스탄", "두샨베"), "TH": ("태국", "방콕"),
    "TL": ("동티모르", "딜리"), "TR": ("튀르키예", "앙카라"), "TM": ("투르크메니스탄", "아시가바트"),
    "AE": ("아랍에미리트", "아부다비"), "UZ": ("우즈베키스탄", "타슈켄트"), "VN": ("베트남", "하노이"),
    "YE": ("예멘", "사나"),
    # Europe
    "AL": ("알바니아", "티라나"), "AD": ("안도라", "안도라라베야"), "AT": ("오스트리아", "빈"),
    "BY": ("벨라루스", "민스크"), "BE": ("벨기에", "브뤼셀"), "BA": ("보스니아헤르체고비나", "사라예보"),
    "BG": ("불가리아", "소피아"), "HR": ("크로아티아", "자그레브"), "CZ": ("체코", "프라하"),
    "DK": ("덴마크", "코펜하겐"), "EE": ("에스토니아", "탈린"), "FI": ("핀란드", "헬싱키"),
    "FR": ("프랑스", "파리"), "DE": ("독일", "베를린"), "GR": ("그리스", "아테네"),
    "HU": ("헝가리", "부다페스트"), "IS": ("아이슬란드", "레이캬비크"), "IE": ("아일랜드", "더블린"),
    "IT": ("이탈리아", "로마"), "XK": ("코소보", "프리슈티나"), "LV": ("라트비아", "리가"),
    "LI": ("리히텐슈타인", "파두츠"), "LT": ("리투아니아", "빌뉴스"), "LU": ("룩셈부르크", "룩셈부르크시"),
    "MT": ("몰타", "발레타"), "MD": ("몰도바", "키시너우"), "MC": ("모나코", "모나코"),
    "ME": ("몬테네그로", "포드고리차"), "NL": ("네덜란드", "암스테르담"), "MK": ("북마케도니아", "스코페"),
    "NO": ("노르웨이", "오슬로"), "PL": ("폴란드", "바르샤바"), "PT": ("포르투갈", "리스본"),
    "RO": ("루마니아", "부쿠레슈티"), "RU": ("러시아", "모스크바"), "SM": ("산마리노", "산마리노"),
    "RS": ("세르비아", "베오그라드"), "SK": ("슬로바키아", "브라티슬라바"), "SI": ("슬로베니아", "류블랴나"),
    "ES": ("스페인", "마드리드"), "SE": ("스웨덴", "스톡홀름"), "CH": ("스위스", "베른"),
    "UA": ("우크라이나", "키이우"), "GB": ("영국", "런던"), "VA": ("바티칸시국", "바티칸시"),
    # North America & Caribbean
    "AG": ("앤티가바부다", "세인트존스"), "BS": ("바하마", "나소"), "BB": ("바베이도스", "브리지타운"),
    "BZ": ("벨리즈", "벨모판"), "CA": ("캐나다", "오타와"), "CR": ("코스타리카", "산호세"),
    "CU": ("쿠바", "아바나"), "DM": ("도미니카연방", "로조"), "DO": ("도미니카공화국", "산토도밍고"),
    "SV": ("엘살바도르", "산살바도르"), "GD": ("그레나다", "세인트조지스"), "GT": ("과테말라", "과테말라시티"),
    "HT": ("아이티", "포르토프랭스"), "HN": ("온두라스", "테구시갈파"), "JM": ("자메이카", "킹스턴"),
    "MX": ("멕시코", "멕시코시티"), "NI": ("니카라과", "마나과"), "PA": ("파나마", "파나마시티"),
    "KN": ("세인트키츠네비스", "바스테르"), "LC": ("세인트루시아", "캐스트리스"),
    "VC": ("세인트빈센트그레나딘", "킹스타운"), "TT": ("트리니다드토바고", "포트오브스페인"),
    "US": ("미국", "워싱턴 D.C."),
    # Oceania
    "AU": ("오스트레일리아", "캔버라"), "FJ": ("피지", "수바"), "KI": ("키리바시", "사우스타라와"),
    "MH": ("마셜제도", "마주로"), "FM": ("미크로네시아 연방", "팔리키르"), "NR": ("나우루", "야렌"),
    "NZ": ("뉴질랜드", "웰링턴"), "PW": ("팔라우", "응게룰무드"), "PG": ("파푸아뉴기니", "포트모르즈비"),
    "WS": ("사모아", "아피아"), "SB": ("솔로몬제도", "호니아라"), "TO": ("통가", "누쿠알로파"),
    "TV": ("투발루", "푸나푸티"), "VU": ("바누아투", "포트빌라"),
    # South America
    "AR": ("아르헨티나", "부에노스아이레스"), "BO": ("볼리비아", "수크레"), "BR": ("브라질", "브라질리아"),
    "CL": ("칠레", "산티아고"), "CO": ("콜롬비아", "보고타"), "EC": ("에콰도르", "키토"),
    "GY": ("가이아나", "조지타운"), "PY": ("파라과이", "아순시온"), "PE": ("페루", "리마"),
    "SR": ("수리남", "파라마리보"), "UY": ("우루과이", "몬테비데오"), "VE": ("베네수엘라", "카라카스"),
}

# Partial Nahuatl country names (well-known; the rest fall back to es-MX). (name_nah, capital_nah?)
COUNTRY_NAH = {
    "MX": ("Mēxihco", "Mēxihco Āltepētl"),
    "GT": ("Cuauhtēmallān", None),
    "US": ("Tlācateccoyān", None),  # descriptive; falls to es-MX if undesired
    "JP": ("Xōchitlālpan", None),
    "CN": ("Chīnatlālli", None),
    "ES": ("Caxtillān", None),
}

# Rivers: id -> name_ko ; selected name_nah
RIVER_KO = {
    "nile": "나일강", "amazon": "아마존강", "yangtze": "양쯔강", "mississippi": "미시시피강",
    "yenisei": "예니세이강", "yellow-river": "황허", "ob": "오브강", "congo": "콩고강",
    "lena": "레나강", "niger": "니제르강", "mekong": "메콩강", "missouri": "미주리강",
    "volga": "볼가강", "zambezi": "잠베지강", "ganges": "갠지스강", "indus": "인더스강",
    "murray": "머리강", "euphrates": "유프라테스강", "tigris": "티그리스강", "rhine": "라인강",
    "danube": "도나우강", "colorado": "콜로라도강", "columbia": "컬럼비아강", "irrawaddy": "이라와디강",
    "orange": "오렌지강", "parana": "파라나강", "amur": "아무르강", "dnieper": "드니프로강",
    "senegal-river": "세네갈강", "orinoco": "오리노코강", "sao-francisco": "상프란시스쿠강",
    "tocantins": "토칸칭스강",
}
RIVER_NAH = {"amazon": "Amazonas Ātōyātl", "mississippi": "Mississippi Ātōyātl"}

# Seas: id -> name_ko ; selected name_nah
SEA_KO = {
    "pacific": "태평양", "atlantic": "대서양", "indian": "인도양", "southern": "남극해",
    "arctic": "북극해", "mediterranean": "지중해", "caribbean": "카리브해", "south-china": "남중국해",
    "bering": "베링해", "gulf-of-mexico": "멕시코만", "north-sea": "북해", "red-sea": "홍해",
    "black-sea": "흑해", "caspian-sea": "카스피해", "persian-gulf": "페르시아만", "east-china": "동중국해",
    "bay-of-bengal": "벵골만", "arabian-sea": "아라비아해", "coral-sea": "산호해", "tasman-sea": "태즈먼해",
}
SEA_NAH = {"caribbean": "Caribe Hueyātl", "pacific": "Pacífico Hueyātl"}

# Mountains: id -> name_ko ; selected name_nah
MOUNTAIN_KO = {
    "himalayas": "히말라야산맥", "andes": "안데스산맥", "rockies": "로키산맥",
    "alps": "알프스산맥", "great-dividing-range": "그레이트디바이딩산맥", "kunlun": "쿤룬산맥",
    "tian-shan": "톈산산맥", "altai": "알타이산맥", "caucasus": "캅카스산맥", "pyrenees": "피레네산맥",
    "carpathians": "카르파티아산맥", "appalachians": "애팔래치아산맥", "atlas": "아틀라스산맥",
    "drakensberg": "드라켄즈버그산맥", "ethiopian-highlands": "에티오피아고원",
    "scandinavian-mountains": "스칸디나비아산맥", "hindu-kush": "힌두쿠시산맥", "karakoram": "카라코람산맥",
    "pamir": "파미르고원", "sierra-nevada-us": "시에라네바다산맥", "southern-alps": "서던알프스산맥",
    "zagros": "자그로스산맥", "eastern-rift-highlands": "동부지구대고원",
}
MOUNTAIN_NAH = {"andes": "Andes Tepētl"}


def load(name):
    with open(os.path.join(RES, f"{name}.json"), encoding="utf-8") as fh:
        return json.load(fh, object_pairs_hook=OrderedDict)


def save(name, data):
    with open(os.path.join(RES, f"{name}.json"), "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


def reorder_after(entry, anchor, new_keys):
    """Return an OrderedDict with new_keys inserted right after `anchor`."""
    out = OrderedDict()
    for k, v in entry.items():
        if k in new_keys:
            continue
        out[k] = v
        if k == anchor:
            for nk in new_keys:
                if nk in new_keys and new_keys[nk] is not None:
                    out[nk] = new_keys[nk]
    return out


def main():
    # Countries
    countries = load("countries")
    for c in countries:
        cid = c["id"]
        adds = OrderedDict()
        if cid in COUNTRY:
            adds["name_ko"] = COUNTRY[cid][0]
        if cid in COUNTRY_NAH and COUNTRY_NAH[cid][0]:
            adds["name_nah"] = COUNTRY_NAH[cid][0]
        # name_* go after name_es
        new = OrderedDict()
        for k, v in c.items():
            if k in ("name_ko", "name_nah", "capital_ko", "capital_nah"):
                continue
            new[k] = v
            if k == "name_es":
                for nk, nv in adds.items():
                    new[nk] = nv
            if k == "capital_es":
                if cid in COUNTRY:
                    new["capital_ko"] = COUNTRY[cid][1]
                if cid in COUNTRY_NAH and COUNTRY_NAH[cid][1]:
                    new["capital_nah"] = COUNTRY_NAH[cid][1]
        countries[countries.index(c)] = new
    save("countries", countries)

    for fname, ko_map, nah_map in [
        ("rivers", RIVER_KO, RIVER_NAH),
        ("seas", SEA_KO, SEA_NAH),
        ("mountains", MOUNTAIN_KO, MOUNTAIN_NAH),
    ]:
        data = load(fname)
        for e in data:
            eid = e["id"]
            new = OrderedDict()
            for k, v in e.items():
                if k in ("name_ko", "name_nah"):
                    continue
                new[k] = v
                if k == "name_es":
                    if eid in ko_map:
                        new["name_ko"] = ko_map[eid]
                    if eid in nah_map:
                        new["name_nah"] = nah_map[eid]
            data[data.index(e)] = new
        save(fname, data)

    print("done")


if __name__ == "__main__":
    main()
