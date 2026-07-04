{
  description = "Hanahuac — Geography Learning App dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Cross-platform linters shared by the dev shell and the CI `lint` shell.
        # These all build on Linux, so the CI lint job (ubuntu) can use them via
        # `nix develop .#lint` without pulling in the macOS-only Xcode tooling below.
        linters = with pkgs; [
          swiftlint # Swift lint rules
          swiftformat # Swift formatter; used in --lint mode as a gate
          ruff # Python linter + formatter for scripts/*.py
          shellcheck # static analysis/linting for scripts/*.sh
          nixfmt # Nix formatter (RFC 166 / rfc-style); used in --check mode as a gate
          yamllint # YAML linter for workflows + project.yml
          actionlint # GitHub Actions workflow semantic linter (.github/workflows/*.yml)
          check-jsonschema # JSON-schema validator; validates .github/dependabot.yml (vendor.dependabot)
        ];
      in
      {
        devShells = {
          # mkShellNoCC: this shell only provides CLI tools (no C compilation), so we must NOT
          # pull in a cc-wrapper stdenv. A plain mkShell exports CC/CXX/LD/SDKROOT/NIX_LDFLAGS/
          # NIX_CFLAGS_COMPILE pointing at nix's toolchain, which leak into and break `xcodebuild`
          # (symptom: `ld: -objc_abi_version '-Xlinker' not supported`). mkShellNoCC keeps Xcode's
          # native toolchain clean.
          default = pkgs.mkShellNoCC {
            packages =
              with pkgs;
              [
                xcodegen # generate .xcodeproj from project.yml (macOS only)
                gh # GitHub CLI for PR workflow
                xcbeautify # pretty xcodebuild output (macOS only)
                jq # process bundled JSON datasets
                just # task runner — short aliases for common commands
                direnv # per-directory env var loading via .envrc
              ]
              # Linters (fail-on-violation gates; see `just lint` and .github/workflows/lint.yml).
              ++ linters;

            shellHook = ''
              export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
              echo "Hanahuac dev shell ready"
              xcodebuild -version 2>/dev/null | head -1 || echo "  (xcodebuild not found — check DEVELOPER_DIR)"
            '';
          };

          # Lint-only shell for CI: just the cross-platform linters, no macOS-only Xcode
          # tooling, so it evaluates and builds on ubuntu-latest. Used by the Lint workflow
          # via `nix develop .#lint --command …`.
          lint = pkgs.mkShellNoCC {
            packages = linters;
          };
        };
      }
    );
}
