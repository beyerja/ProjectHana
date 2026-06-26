#!/usr/bin/env python3
"""One-shot localization injector for story 003 (small UI polish).

Appends the five new keys introduced by this story to every
``Hanahuac/<code>.lproj/Localizable.strings`` file, with a per-locale translation:

  - stats.tier.name.new / .learning / .review / .mastered — short column/legend names for the
    Progress per-category table (AC7).
  - a11y.back — accessibility label for the custom map-learning back button (AC4).

Idempotent: a key already present in a locale is left untouched (so re-running is safe). Stdlib-only.
"""

from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LPROJ_DIR = REPO_ROOT / "Hanahuac"

# key -> {locale: value}. Every on-disk locale gets a value (the l10n gate's canonical key set is the
# union across locales; required locales must carry every canonical key).
TRANSLATIONS: dict[str, dict[str, str]] = {
    "stats.tier.name.new": {
        "en": "New",
        "es-MX": "Nuevo",
        "es-ES": "Nuevo",
        "de": "Neu",
        "fr": "Nouveau",
        "it": "Nuovo",
        "pl": "Nowe",
        "nl": "Nieuw",
        "sr": "Ново",
        "ko": "신규",
        "nah": "Yancuic",
        "yua": "Túumben",
        "ca": "Nou",
        "eu": "Berria",
        "ja": "新規",
        "zh-Hans": "新增",
        "hi": "नया",
        "ar": "جديد",
        "bn": "নতুন",
        "pt-BR": "Novo",
        "ur": "نیا",
    },
    "stats.tier.name.learning": {
        "en": "Learning",
        "es-MX": "Aprendiendo",
        "es-ES": "Aprendiendo",
        "de": "Lernen",
        "fr": "Apprentissage",
        "it": "In apprendimento",
        "pl": "Nauka",
        "nl": "Leren",
        "sr": "Учење",
        "ko": "학습 중",
        "nah": "Momachtia",
        "yua": "Táan u kanik",
        "ca": "Aprenent",
        "eu": "Ikasten",
        "ja": "学習中",
        "zh-Hans": "学习中",
        "hi": "सीख रहे",
        "ar": "قيد التعلّم",
        "bn": "শিখছে",
        "pt-BR": "Aprendendo",
        "ur": "سیکھ رہے",
    },
    "stats.tier.name.review": {
        "en": "Review",
        "es-MX": "Repaso",
        "es-ES": "Repaso",
        "de": "Wiederholung",
        "fr": "Révision",
        "it": "Ripasso",
        "pl": "Powtórka",
        "nl": "Herhaling",
        "sr": "Преглед",
        "ko": "복습",
        "nah": "Tlachializtli",
        "yua": "Ka'a ila'",
        "ca": "Repàs",
        "eu": "Berrikuspena",
        "ja": "復習",
        "zh-Hans": "复习",
        "hi": "समीक्षा",
        "ar": "مراجعة",
        "bn": "পর্যালোচনা",
        "pt-BR": "Revisão",
        "ur": "نظرثانی",
    },
    "stats.tier.name.mastered": {
        "en": "Mastered",
        "es-MX": "Dominado",
        "es-ES": "Dominado",
        "de": "Gemeistert",
        "fr": "Maîtrisé",
        "it": "Padroneggiato",
        "pl": "Opanowane",
        "nl": "Beheerst",
        "sr": "Савладано",
        "ko": "완료",
        "nah": "Tlamachtilli",
        "yua": "Ts'o'ok u kanik",
        "ca": "Dominat",
        "eu": "Menderatua",
        "ja": "習得済み",
        "zh-Hans": "已掌握",
        "hi": "महारत",
        "ar": "متقَن",
        "bn": "আয়ত্ত",
        "pt-BR": "Dominado",
        "ur": "مہارت",
    },
    "a11y.back": {
        "en": "Back",
        "es-MX": "Atrás",
        "es-ES": "Atrás",
        "de": "Zurück",
        "fr": "Retour",
        "it": "Indietro",
        "pl": "Wstecz",
        "nl": "Terug",
        "sr": "Назад",
        "ko": "뒤로",
        "nah": "Tlacuepa",
        "yua": "Suunajil",
        "ca": "Enrere",
        "eu": "Atzera",
        "ja": "戻る",
        "zh-Hans": "返回",
        "hi": "वापस",
        "ar": "رجوع",
        "bn": "ফিরে যান",
        "pt-BR": "Voltar",
        "ur": "واپس",
    },
}

HEADER = "\n/* Story 003 — Progress tier names + map back button (AC4 / AC7) */\n"


def discover_locales() -> list[str]:
    codes = []
    for lproj in LPROJ_DIR.glob("*.lproj"):
        if (lproj / "Localizable.strings").exists():
            codes.append(lproj.name[: -len(".lproj")])
    return sorted(codes)


def main() -> int:
    for code in discover_locales():
        path = LPROJ_DIR / f"{code}.lproj" / "Localizable.strings"
        text = path.read_text(encoding="utf-8")
        additions = []
        for key, by_locale in TRANSLATIONS.items():
            if f'"{key}"' in text:
                continue  # idempotent: already present
            value = by_locale.get(code, by_locale["en"])
            additions.append(f'"{key}" = "{value}";')
        if not additions:
            continue
        block = HEADER + "\n".join(additions) + "\n"
        if not text.endswith("\n"):
            block = "\n" + block
        path.write_text(text + block, encoding="utf-8")
        print(f"  {code}: added {len(additions)} key(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
