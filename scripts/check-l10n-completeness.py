#!/usr/bin/env python3
"""Static localization-completeness gate for ProjectHana (stdlib-only, zero dependencies).

Parses every ``Hanahuac/<code>.lproj/Localizable.strings`` and enforces:

  (a) The canonical key set is the UNION of all keys found across every locale.
  (b) Every BASE / always-bundled locale (en, es-MX) and every fully-translated downloadable
      locale (de, fr, ko) must contain the FULL canonical key set. Any missing key fails the
      check, listing the offending locale + keys.
  (c) ``nah`` is allowed to be a PARTIAL subset: the established nah -> es-MX -> en fallback
      convention (see Hanahuac/L10n/L10n.swift bundleCandidates) serves any missing nah key from
      Mexican Spanish, then English. nah coverage is reported as INFORMATIONAL, never a failure.
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
# Base / always-bundled locales: must be 100% complete.
BASE_LOCALES = ("en", "es-MX")
# Fully-translated downloadable locales: must be 100% complete.
FULL_LOCALES = ("de", "fr", "ko")
# Partial-by-design locale: allowed to be a subset (nah -> es-MX -> en fallback convention).
PARTIAL_LOCALES = ("nah",)

REQUIRED_LOCALES = BASE_LOCALES + FULL_LOCALES
ALL_LOCALES = BASE_LOCALES + FULL_LOCALES + PARTIAL_LOCALES

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


def load_all() -> dict[str, dict[str, str]]:
    """Load every locale's parsed strings, keyed by locale code."""
    tables: dict[str, dict[str, str]] = {}
    for code in ALL_LOCALES:
        path = LPROJ_DIR / f"{code}.lproj" / "Localizable.strings"
        if not path.exists():
            print(f"FAIL: missing strings file for locale '{code}': {path}", file=sys.stderr)
            sys.exit(1)
        tables[code] = parse_strings(path)
    return tables


def main() -> int:
    tables = load_all()

    # (a) Canonical key set = union of all keys across every locale.
    canonical: set[str] = set()
    for table in tables.values():
        canonical |= set(table.keys())

    print(
        f"== l10n completeness: {len(canonical)} canonical keys across {len(ALL_LOCALES)} locales =="
    )
    for code in ALL_LOCALES:
        count = len(tables[code])
        print(f"  {code:>6}: {count} keys")

    failures: list[str] = []

    # (b) Required locales must contain the full canonical key set.
    for code in REQUIRED_LOCALES:
        missing = sorted(canonical - set(tables[code].keys()))
        if missing:
            failures.append(
                f"locale '{code}' is missing {len(missing)} required key(s): " + ", ".join(missing)
            )

    # (c) nah is allowed to be partial — report coverage informationally only.
    for code in PARTIAL_LOCALES:
        present = len(set(tables[code].keys()) & canonical)
        pct = (present / len(canonical) * 100) if canonical else 0.0
        print(
            f"== info: partial locale '{code}' covers {present}/{len(canonical)} keys "
            f"({pct:.0f}%); the rest resolve via {code} -> es-MX -> en fallback (by design) =="
        )

    # (d) Untranslated-value warnings: non-base value byte-identical to en for the same key.
    en = tables["en"]
    warnings: list[str] = []
    for code in FULL_LOCALES:
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
