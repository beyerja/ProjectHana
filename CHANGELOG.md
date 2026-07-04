<!--
Release procedure: as part of the version-bump PR, move the [Unreleased] content under a new
`## [X.Y.Z] - YYYY-MM-DD` heading (matching the bumped MARKETING_VERSION in project.yml) and
leave a fresh empty [Unreleased] section on top. Full runbook: docs/releasing.md (story 005).
-->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Hanahuac geography-learning app (map quiz, multiple choice, flashcards) in its current
  pre-release state: the app is at `MARKETING_VERSION` 1.0.0 with no tagged releases yet.
- Versioning and bump tooling: `project.yml` is the single source of truth for the version;
  `just bump <major|minor|patch>` updates it and regenerates the Xcode project (story 001).
- This changelog, plus scripted release-consistency checks (`scripts/check-changelog.sh`,
  `scripts/check-tag-version.sh`) that later gate releases.
