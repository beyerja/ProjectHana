## Tasks
- [x] 001: Add `shellcheck` to the `flake.nix` dev shell `packages` (from nixpkgs, via flake + direnv; no hardcoded /nix path)
- [x] 002: Add a `just lint-sh` recipe that runs `shellcheck` over the tracked shell scripts under `scripts/` (and any other tracked `.sh`), matching existing recipe style (comment header + body); PATH via flake/direnv
- [x] 003: Run `just lint-sh` against the current `scripts/*.sh`; fix or annotate (with justified `# shellcheck disable=...`) any findings so it exits zero — fixed SC2015 in install-mac.sh by converting `A && B || C` to `if/then/else`
