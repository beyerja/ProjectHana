{
  description = "Hanahuac — Geography Learning App dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # mkShellNoCC: this shell only provides CLI tools (no C compilation), so we must NOT
        # pull in a cc-wrapper stdenv. A plain mkShell exports CC/CXX/LD/SDKROOT/NIX_LDFLAGS/
        # NIX_CFLAGS_COMPILE pointing at nix's toolchain, which leak into and break `xcodebuild`
        # (symptom: `ld: -objc_abi_version '-Xlinker' not supported`). mkShellNoCC keeps Xcode's
        # native toolchain clean.
        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            xcodegen    # generate .xcodeproj from project.yml
            gh          # GitHub CLI for PR workflow
            xcbeautify  # pretty xcodebuild output
            jq          # process bundled JSON datasets
            swiftformat # optional: format Swift source
            shellcheck  # static analysis/linting for the scripts/*.sh hook scripts
            just        # task runner — short aliases for common commands
            direnv      # per-directory env var loading via .envrc
          ];

          shellHook = ''
            export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
            echo "Hanahuac dev shell ready"
            xcodebuild -version 2>/dev/null | head -1 || echo "  (xcodebuild not found — check DEVELOPER_DIR)"
          '';
        };
      }
    );
}
