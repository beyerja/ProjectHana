{
  description = "ProjectHana — Geography Learning App dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            xcodegen    # generate .xcodeproj from project.yml
            gh          # GitHub CLI for PR workflow
            xcbeautify  # pretty xcodebuild output
            jq          # process bundled JSON datasets
            swiftformat # optional: format Swift source
          ];

          shellHook = ''
            export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
            echo "ProjectHana dev shell ready"
            xcodebuild -version 2>/dev/null | head -1 || echo "  (xcodebuild not found — check DEVELOPER_DIR)"
          '';
        };
      }
    );
}
