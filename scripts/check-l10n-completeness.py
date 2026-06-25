#!/usr/bin/env python3
"""Static localization-completeness gate for ProjectHana (stdlib-only, zero dependencies).

Parses every ``Hanahuac/<code>.lproj/Localizable.strings`` and enforces:

  (a) The canonical key set is the UNION of all keys found across every locale.
  (b) Every locale is assigned an explicit ENFORCEMENT ROLE in ``ROLE_MAP`` (the single source of
      truth, keyed by locale code). The enforced locale set is DATA-DRIVEN: it is *discovered* from
      the ``Hanahuac/<code>.lproj`` dirs that actually exist on disk, so a newly-added ``.lproj`` can
      never be silently skipped. Every on-disk locale MUST have a declared role; an unclassified
      on-disk locale fails the check (catch a new ``.lproj`` that nobody assigned a role).
        - ``BASE`` (en, es-MX): always-bundled, must contain the FULL canonical key set.
        - ``FULL`` (de, fr, es-ES, it, pl, nl, sr, ko and the future 7): fully-translated canonical
          locales, must contain the FULL canonical key set. Any missing key fails, listing the
          offending locale + keys.
        - ``PARTIAL`` (nah, yua, ca, eu): fallback-permitted by design — genuine gaps resolve via the
          locale's fallback chain (e.g. nah/yua -> es-MX -> en; ca/eu -> es-ES -> en; see
          Hanahuac/L10n/LanguageCatalog.swift fallbackChain). Their coverage is reported as
          INFORMATIONAL, never a failure.
  (c) Future locales (ja, zh-Hans, hi, ar, bn, pt-BR, ur) are PRE-DECLARED ``FULL`` in ``ROLE_MAP``
      but enforced ONLY once their ``.lproj`` exists on disk: a declared-but-absent locale is skipped
      silently (it is owned by its language story 002+); a declared locale whose ``.lproj`` exists is
      held to the full canonical key set.
  (d) Untranslated values are detected: a non-base locale value byte-identical to the en value for
      the same key is reported as a WARNING (so a copy-paste-but-forgot-to-translate slips no
      further), with an allowlist for legitimately-identical strings (brand names, ISO/shared
      tokens, symbols) so the warning list stays signal, not noise.

Mirrors the spirit of scripts/verify-odr-packs.sh: a single committed gate, exits non-zero on a
real defect, prints a clear human-readable report. Wired into ``just l10n-check`` / ``just lint``.

Exit status: 0 when all required locales are complete (warnings do not fail the build); 1 on any
missing required key or a parse error.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# --- Locale roles ----------------------------------------------------------------------------
# Enforcement roles. A locale's role determines how its key set is checked.
BASE = "base"  # always-bundled (en, es-MX) — must contain the FULL canonical key set.
FULL = "full"  # fully-translated canonical locale — must contain the FULL canonical key set.
PARTIAL = "partial"  # fallback-permitted by design — coverage is informational, never a failure.

# Single source of truth for every locale's enforcement role, keyed by locale code. The set of
# locales actually CHECKED is discovered from the on-disk `.lproj` dirs (see discover_locales); this
# map only assigns each one a role. Every on-disk locale MUST appear here or the check fails, so a
# new `.lproj` can never be added without being given an explicit enforcement role.
#
# The 7 future locales (ja, zh-Hans, hi, ar, bn, pt-BR, ur) are pre-declared FULL here but are only
# enforced once their `.lproj` exists on disk (a declared-but-absent locale is skipped silently —
# it is owned by its respective language story 002+). When their story adds the `.lproj`, they are
# automatically held to the full canonical key set with no further change to this gate.
ROLE_MAP: dict[str, str] = {
    # Base / always-bundled — 100% complete.
    "en": BASE,
    "es-MX": BASE,
    # Fully-translated canonical locales — 100% complete. es-ES (Castilian), it (Italian),
    # pl (Polish), nl (Dutch), and sr (Serbian, Cyrillic) ship a complete UI string set (their
    # feature contracts assert no missing keys), held to the full canonical set like de/fr/ko.
    "de": FULL,
    "fr": FULL,
    "es-ES": FULL,
    "it": FULL,
    "pl": FULL,
    "nl": FULL,
    "sr": FULL,
    "ko": FULL,
    # Partial / fallback-permitted by design — genuine gaps resolve via the locale's fallback chain
    # (LanguageCatalog.fallbackChain): nah/yua -> es-MX -> en; ca/eu -> es-ES -> en. Coverage is
    # reported informationally only, never a failure.
    "nah": PARTIAL,
    "yua": PARTIAL,
    "ca": PARTIAL,
    "eu": PARTIAL,
    # --- Future locales: pre-declared FULL, enforced only once their `.lproj` lands on disk. ---
    # Each is activated by its respective language story (002+); until then it is skipped silently.
    "ja": FULL,
    "zh-Hans": FULL,
    "hi": FULL,
    "ar": FULL,
    "bn": FULL,
    "pt-BR": FULL,
    "ur": FULL,
}

REPO_ROOT = Path(__file__).resolve().parent.parent
LPROJ_DIR = REPO_ROOT / "Hanahuac"

# Keys whose value is *expected* to read identically to English in a translated locale, because the
# string is a brand name, an ISO/shared token, a proper noun, or a punctuation-only format string.
# Each entry is a (locale, key) pair so an allowance is scoped to exactly where it is legitimate.
# Keep this list short and clearly justified — every entry suppresses a real "looks untranslated"
# signal, so only add genuinely-shared strings.
IDENTICAL_VALUE_ALLOWLIST: set[tuple[str, str]] = {
    # German uses the English term "Multiple Choice" as a standard loanword for this quiz mode.
    ("de", "quiz.mode.multiple_choice.title"),
    ("de", "learn.mode_picker.mcq.title"),
    # "Status" is spelled identically in German.
    ("de", "settings.sync.status_label"),
    # French cognates that are spelled identically to English (correct translations, not stubs).
    ("fr", "a11y.feedback.correct"),  # "Correct"
    ("fr", "a11y.feedback.incorrect"),  # "Incorrect"
    ("fr", "a11y.prompt.label"),  # "Question"
    ("fr", "quiz_summary.correct"),  # "Correct"
    # "%d correct" — "correct" is identical in French; the rest is a format specifier.
    ("fr", "capital_quiz.correct_count"),
    ("fr", "mcq_quiz.correct_count"),
    # "Europe" is spelled identically in English and French.
    ("fr", "continent.europe"),
    # "iCloud" is an Apple brand name — identical in every language.
    ("de", "settings.section.icloud"),
    ("fr", "settings.section.icloud"),
    ("ko", "settings.section.icloud"),
    # "%d / 3" is a pure format string (digit + slash); identical in every language.
    ("de", "learn_map.streak"),
    ("fr", "learn_map.streak"),
    ("ko", "learn_map.streak"),
    # es-ES (Castilian) shared strings: proper noun "Asia", the "%d / 3" format string, the loanword
    # "General", the Apple brand "iCloud", and "Error" (identical in Spanish) — all legitimately
    # identical to English, not untranslated stubs.
    ("es-ES", "continent.asia"),
    ("es-ES", "learn_map.streak"),
    ("es-ES", "settings.section.general"),
    ("es-ES", "settings.section.icloud"),
    ("es-ES", "settings.sync.status.error"),
    # it (Italian) shared strings: the continent proper nouns "Africa"/"Asia"/"Oceania" are spelled
    # identically in Italian, "iCloud" is an Apple brand, and "%d / 3" is a pure format string — all
    # legitimately identical to English, not untranslated stubs.
    ("it", "continent.africa"),
    ("it", "continent.asia"),
    ("it", "continent.oceania"),
    ("it", "settings.section.icloud"),
    ("it", "learn_map.streak"),
    # pl (Polish) shared strings: the continent proper noun "Oceania" is spelled identically in
    # Polish, "iCloud" is an Apple brand, and "%d / 3" is a pure format string — all legitimately
    # identical to English, not untranslated stubs.
    ("pl", "continent.oceania"),
    ("pl", "settings.section.icloud"),
    ("pl", "learn_map.streak"),
    # nl (Dutch) shared strings: "iCloud" is an Apple brand, "%d / 3" is a pure format string, and
    # "Status" is spelled identically in Dutch — all legitimately identical to English, not stubs.
    ("nl", "settings.section.icloud"),
    ("nl", "learn_map.streak"),
    ("nl", "settings.sync.status_label"),
    # sr (Serbian, Cyrillic) shared strings: "iCloud" is an Apple brand and "%d / 3" is a pure format
    # string — both legitimately identical to English. Every other sr value is Cyrillic, so nothing
    # else can collide with the Latin-script English values.
    ("sr", "settings.section.icloud"),
    ("sr", "learn_map.streak"),
}


def parse_strings(path: Path) -> dict[str, str]:
    """Parse a ``Localizable.strings`` file into an ordered ``{key: value}`` dict.

    Handles the standard ``"key" = "value";`` form with escaped quotes inside values, and skips
    ``/* ... */`` block comments and ``//`` line comments. Stdlib regex only.
    """
    text = path.read_text(encoding="utf-8")
    # Strip /* ... */ block comments (non-greedy, across newlines).
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    # Strip // line comments.
    text = re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)
    pattern = re.compile(
        r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;',
        flags=re.DOTALL,
    )
    result: dict[str, str] = {}
    for match in pattern.finditer(text):
        key = match.group(1)
        value = match.group(2)
        result[key] = value
    return result


def discover_locales() -> list[str]:
    """Discover the locale codes to check from the `Hanahuac/<code>.lproj` dirs on disk.

    Each `<code>.lproj` that contains a `Localizable.strings` file is a locale to enforce. The set is
    DATA-DRIVEN (read from the filesystem) rather than hardcoded, so a newly-added `.lproj` is picked
    up automatically and cannot be silently skipped. Returns the codes sorted for deterministic
    output.
    """
    codes: list[str] = []
    for lproj in LPROJ_DIR.glob("*.lproj"):
        if (lproj / "Localizable.strings").exists():
            codes.append(lproj.name[: -len(".lproj")])
    return sorted(codes)


def load_all(codes: list[str]) -> dict[str, dict[str, str]]:
    """Load each discovered locale's parsed strings, keyed by locale code."""
    tables: dict[str, dict[str, str]] = {}
    for code in codes:
        path = LPROJ_DIR / f"{code}.lproj" / "Localizable.strings"
        if not path.exists():
            print(f"FAIL: missing strings file for locale '{code}': {path}", file=sys.stderr)
            sys.exit(1)
        tables[code] = parse_strings(path)
    return tables


def main() -> int:
    # Discover the locales actually present on disk and confirm each has a declared role. An on-disk
    # `.lproj` with no entry in ROLE_MAP fails: every locale must be explicitly classified so a new
    # `.lproj` can never be added without being assigned an enforcement role.
    on_disk = discover_locales()
    unclassified = [code for code in on_disk if code not in ROLE_MAP]
    if unclassified:
        print(
            "FAIL: on-disk locale(s) with no declared role in ROLE_MAP: " + ", ".join(unclassified),
            file=sys.stderr,
        )
        print(
            "  Add each to ROLE_MAP in scripts/check-l10n-completeness.py with role "
            "base/full/partial.",
            file=sys.stderr,
        )
        return 1

    tables = load_all(on_disk)

    base_locales = [code for code in on_disk if ROLE_MAP[code] == BASE]
    full_locales = [code for code in on_disk if ROLE_MAP[code] == FULL]
    partial_locales = [code for code in on_disk if ROLE_MAP[code] == PARTIAL]
    required_locales = base_locales + full_locales

    declared_absent = sorted(
        code for code, role in ROLE_MAP.items() if role == FULL and code not in tables
    )

    # (a) Canonical key set = union of all keys across every on-disk locale.
    canonical: set[str] = set()
    for table in tables.values():
        canonical |= set(table.keys())

    print(f"== l10n completeness: {len(canonical)} canonical keys across {len(on_disk)} locales ==")
    for code in on_disk:
        count = len(tables[code])
        print(f"  {code:>7}: {count} keys [{ROLE_MAP[code]}]")
    if declared_absent:
        print(
            "== info: future FULL locale(s) declared but not yet on disk (enforced once their "
            ".lproj lands): " + ", ".join(declared_absent) + " =="
        )

    failures: list[str] = []

    # (b) Base + full locales must contain the full canonical key set.
    for code in required_locales:
        missing = sorted(canonical - set(tables[code].keys()))
        if missing:
            failures.append(
                f"locale '{code}' is missing {len(missing)} required key(s): " + ", ".join(missing)
            )

    # (c) Partial-by-design locales (nah, yua, ca, eu) — report coverage informationally only; their
    # genuine gaps resolve via the locale's fallback chain (LanguageCatalog.fallbackChain).
    for code in partial_locales:
        present = len(set(tables[code].keys()) & canonical)
        pct = (present / len(canonical) * 100) if canonical else 0.0
        print(
            f"== info: partial locale '{code}' covers {present}/{len(canonical)} keys "
            f"({pct:.0f}%); the rest resolve via the {code} fallback chain (by design) =="
        )

    # (d) Untranslated-value warnings: non-base value byte-identical to en for the same key.
    en = tables["en"]
    warnings: list[str] = []
    for code in full_locales:
        table = tables[code]
        for key, value in sorted(table.items()):
            if key not in en:
                continue
            if value == en[key] and (code, key) not in IDENTICAL_VALUE_ALLOWLIST:
                warnings.append(f"  {code}: '{key}' is byte-identical to English ({value!r})")

    if warnings:
        print("== warnings: non-base values identical to English (verify these are intentional) ==")
        for line in warnings:
            print(line)
        print(
            "  (legitimately-shared strings — brand names, ISO/symbol tokens — belong in "
            "IDENTICAL_VALUE_ALLOWLIST in this script.)"
        )

    if failures:
        print("\nFAIL: localization completeness violations:", file=sys.stderr)
        for line in failures:
            print(f"  - {line}", file=sys.stderr)
        return 1

    print("\nl10n-check: PASS — all required locales contain the full canonical key set.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
