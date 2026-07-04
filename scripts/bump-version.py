#!/usr/bin/env python3
"""Bump the app version in project.yml and regenerate the Xcode project.

Versioning / tagging convention
-------------------------------
* `project.yml` is the SINGLE SOURCE OF TRUTH for the app version:
  - MARKETING_VERSION: strict three-component semver `X.Y.Z` (all numeric), and
  - CURRENT_PROJECT_VERSION: a monotonically increasing positive integer build number.
  No version value may be introduced anywhere else; the committed
  `Hanahuac.xcodeproj/project.pbxproj` is regenerated output, never hand-edited.
* Releases are annotated `v<MAJOR>.<MINOR>.<PATCH>` tags on `main` only.
* Manual edits to these fields are discouraged — use `just bump <major|minor|patch>`
  instead (the full release runbook lands in story 005).

Behavior
--------
`bump-version.py <major|minor|patch>` bumps the requested semver part (resetting the
lower parts to 0), increments the build number by 1, rewrites ONLY those two lines in
`project.yml` (the rest of the file is preserved byte-for-byte), and then regenerates
the Xcode project the same way `just generate` does (`direnv exec . xcodegen generate`).

Options:
  --file PATH     operate on PATH instead of ./project.yml (used by the tests)
  --no-generate   skip the xcodegen regeneration step (used by the tests)

All validation failures (invalid part, non-semver current version, non-integer build
number, missing/duplicated keys) print a clear message to stderr and exit non-zero.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

MARKETING_RE = re.compile(r'^\s*MARKETING_VERSION:\s*"(?P<value>[^"]*)"', re.MULTILINE)
BUILD_RE = re.compile(r'^\s*CURRENT_PROJECT_VERSION:\s*"(?P<value>[^"]*)"', re.MULTILINE)
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def fail(message: str) -> NoReturn:
    print(f"bump-version: ERROR: {message}", file=sys.stderr)
    sys.exit(1)


def find_single_match(pattern: re.Pattern, text: str, key: str) -> re.Match:
    matches = list(pattern.finditer(text))
    if not matches:
        fail(f'no `{key}: "…"` line found in the target file (is it a valid project.yml?)')
    if len(matches) > 1:
        fail(f"`{key}` matched {len(matches)} lines; expected exactly one")
    return matches[0]


def bump_semver(current: str, part: str) -> str:
    match = SEMVER_RE.match(current)
    if not match:
        fail(
            f"MARKETING_VERSION {current!r} is not strict three-component semver (X.Y.Z, "
            "all numeric). Normalize it in project.yml first (see story "
            "001-versioning-bump-tooling, task 001, e.g. 1.0 -> 1.0.0)."
        )
    major, minor, patch = (int(g) for g in match.groups())
    if part == "major":
        return f"{major + 1}.0.0"
    if part == "minor":
        return f"{major}.{minor + 1}.0"
    return f"{major}.{minor}.{patch + 1}"


def bump_build(current: str) -> str:
    if not current.isdigit() or int(current) < 1:
        fail(f"CURRENT_PROJECT_VERSION {current!r} is not a positive integer")
    return str(int(current) + 1)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Bump MARKETING_VERSION / CURRENT_PROJECT_VERSION in project.yml "
        "and regenerate the Xcode project. See the module docstring for the convention."
    )
    parser.add_argument("part", choices=("major", "minor", "patch"), help="semver part to bump")
    parser.add_argument(
        "--file",
        default="project.yml",
        help="path to the project.yml to edit (default: ./project.yml)",
    )
    parser.add_argument(
        "--no-generate",
        action="store_true",
        help="skip `direnv exec . xcodegen generate` after editing (for tests)",
    )
    args = parser.parse_args()

    target = Path(args.file)
    if not target.is_file():
        fail(f"target file not found: {target}")
    text = target.read_text(encoding="utf-8")

    marketing = find_single_match(MARKETING_RE, text, "MARKETING_VERSION")
    build = find_single_match(BUILD_RE, text, "CURRENT_PROJECT_VERSION")

    old_version = marketing.group("value")
    old_build = build.group("value")
    new_version = bump_semver(old_version, args.part)
    new_build = bump_build(old_build)

    # Replace only the value spans, later span first, so earlier offsets stay valid and
    # every other byte of the file is preserved exactly.
    spans = sorted(
        (
            (marketing.span("value"), new_version),
            (build.span("value"), new_build),
        ),
        reverse=True,
    )
    for (start, end), replacement in spans:
        text = text[:start] + replacement + text[end:]
    target.write_text(text, encoding="utf-8")

    print(f"MARKETING_VERSION: {old_version} -> {new_version}")
    print(f"CURRENT_PROJECT_VERSION: {old_build} -> {new_build}")

    if args.no_generate:
        return

    result = subprocess.run(
        ["direnv", "exec", ".", "xcodegen", "generate"], cwd=target.resolve().parent, check=False
    )
    if result.returncode != 0:
        fail(f"xcodegen regeneration failed (exit {result.returncode})")


if __name__ == "__main__":
    main()
