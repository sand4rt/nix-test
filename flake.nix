{
  description = "A declarative testing framework for testing user-facing behavior in Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs =
    { self, nixpkgs, ... }:
    {
      overlays.default = import ./overlay.nix;
      flakeModules.default = import ./module.nix;
      lib.fixtures = import ./lib/fixtures.nix;
      lib.mkTests = args: (import ./lib/mk-tests.nix) args;

      packages = builtins.mapAttrs (
        system: pkgs:
        let
          apiReference = import ./docs/generate-api.nix { inherit (pkgs) lib; };
          generatedApi = pkgs.writeText "api.md" apiReference;
          generateDocs = pkgs.writeShellApplication {
            name = "generate-docs";
            text = ''
              cp ${generatedApi} docs/src/reference/api.md
            '';
          };
          docs = pkgs.stdenvNoCC.mkDerivation {
            pname = "nix-tests-docs";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = [
              pkgs.mdbook
            ];
            buildPhase = ''
              runHook preBuild
              cmp docs/src/reference/api.md ${generatedApi}
              mkdir -p "$out"
              mdbook build --dest-dir "$out"
              runHook postBuild
            '';
            dontInstall = true;
          };
        in
        {
          runner = pkgs.writeText "tui-test-runner.py" (import ./lib/runner.nix);
          inherit docs generateDocs;
          default = docs;
        }
      ) nixpkgs.legacyPackages;

      apps = builtins.mapAttrs (
        system: pkgs:
        {
          generate-docs = {
            type = "app";
            program = "${self.packages.${system}.generateDocs}/bin/generate-docs";
            meta.description = "Regenerate the committed API reference";
          };
        }
      ) nixpkgs.legacyPackages;

      checks = builtins.mapAttrs (
        system: pkgs:
        {
          docs = self.packages.${system}.docs;
        }
      ) nixpkgs.legacyPackages;
    };
}
