#!/usr/bin/env python3
"""One-shot cleanup: remove the orphaned quiz "exit" / "Salir" L10n keys (story 002).

Story 002 (Harden quiz exit) removes the redundant `.cancellationAction` "Salir" toolbar exit button
from every quiz view, keeping the system back chevron as the single back control (AC6). That leaves
these four keys referenced nowhere in the Swift sources, so they are deleted from EVERY
`Hanahuac/<code>.lproj/Localizable.strings` to keep all locales in sync (the l10n-completeness gate's
canonical key set is the union across all locales, so a key removed everywhere stays balanced).

Idempotent: removing already-absent keys is a no-op. Run via `just` or directly with python3.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LPROJ_DIR = REPO / "Hanahuac"
ORPHANED_KEYS = ["learn.exit", "map_quiz.exit", "mcq_quiz.exit", "capital_quiz.exit"]


def main() -> int:
    removed_total = 0
    files = sorted(LPROJ_DIR.glob("*.lproj/Localizable.strings"))
    if not files:
        print("no Localizable.strings files found", file=sys.stderr)
        return 1
    for path in files:
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
        kept: list[str] = []
        removed_here = 0
        for line in lines:
            match = re.match(r'^\s*"([^"]+)"\s*=', line)
            if match and match.group(1) in ORPHANED_KEYS:
                removed_here += 1
                continue
            kept.append(line)
        if removed_here:
            path.write_text("".join(kept), encoding="utf-8")
            removed_total += removed_here
            print(f"  {path.relative_to(REPO)}: removed {removed_here} key(s)")
    print(
        f"done: removed {removed_total} orphaned exit key line(s) across {len(files)} locale file(s)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
