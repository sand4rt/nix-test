{
  description = "A declarative testing framework for testing user-facing behavior in Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nvf = {
    url = "github:NotAShelf/nvf";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      nvf,
      ...
    }:
    let
      moduleConsumer = flake-parts.lib.mkFlake { inherit inputs; } {
        imports = [
          self.flakeModules.default
          ./core/extensions.test.nix
          ./tests/neotest-nix.test.nix
        ];
        systems = builtins.attrNames nixpkgs.legacyPackages;
        perSystem =
          { pkgs, ... }:
          {
            imports = [
              ./browser/fixture.test.nix
              ./container/fixture.test.nix
              ./desktop/fixture.test.nix
              ./expect/fixture.test.nix
              ./filesystem/fixture.test.nix
              ./http/fixture.test.nix
              ./machine/fixture.test.nix
              ./network/fixture.test.nix
              ./result/fixture.test.nix
              ./user/fixture.test.nix
              ./service/fixture.test.nix
              ./step/fixture.test.nix
              ./workspace/fixture.test.nix
              ./terminal/terminal.test.nix
            ];
            test = {
              configure = {
                timeout = 20;
                terminal = {
                  columns = 100;
                  rows = 30;
                };
              };
              "interop passes" = { terminal, expect }: [
                (terminal.open pkgs.hello)
                (expect.toBeVisible (terminal.getByText "Hello"))
              ];
            };
          };
      };
    in
    {
      overlays.default = import ./overlay.nix;
      flakeModules.default = import ./module.nix;
      lib =
        let
          builders = import ./core/builders.nix;
        in
        builders
        // {
        test = import ./step/fixture.nix builders;
        fixtures =
          { pkgs }:
          import ./core/fixtures.nix {
            inherit pkgs;
            inherit (pkgs) lib;
          };
        mkTests = import ./core/mk-tests.nix;
        };

      packages = builtins.mapAttrs (
        system: pkgs:
        let
          apiReference = import ./docs/generate-api.nix { inherit (pkgs) lib; };
          generatedApi = builtins.mapAttrs (name: content: pkgs.writeText "${name}.md" content) apiReference;
          generateDocs = pkgs.writeShellApplication {
            name = "generate-docs";
            text = ''
              cp ${generatedApi.core} docs/src/reference/core.md
              cp ${generatedApi.terminal} docs/src/reference/terminal.md
            '';
          };
          docs = pkgs.stdenvNoCC.mkDerivation {
            pname = "nix-test-docs";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = [
              pkgs.mdbook
            ];
            buildPhase = ''
              runHook preBuild
               cmp docs/src/reference/core.md ${generatedApi.core}
               cmp docs/src/reference/terminal.md ${generatedApi.terminal}
              mkdir -p "$out"
              mdbook build --dest-dir "$out"
              runHook postBuild
            '';
            dontInstall = true;
          };
        in
        {
          inherit docs generateDocs;
          default = docs;
        }
      ) nixpkgs.legacyPackages;

      apps = builtins.mapAttrs (system: pkgs: {
        generate-docs = {
          type = "app";
          program = "${self.packages.${system}.generateDocs}/bin/generate-docs";
          meta.description = "Regenerate the committed API reference";
        };
      }) nixpkgs.legacyPackages;

      checks = builtins.mapAttrs (
        system: pkgs:
        moduleConsumer.checks.${system}
        // {
          docs = self.packages.${system}.docs;
          builders-unit = import ./core/builders.test.nix {
            inherit pkgs;
            builders = import ./core/builders.nix;
          };
          mk-tests-unit = import ./core/mk-tests.test.nix {
            inherit pkgs;
            builders = import ./core/builders.nix;
            mkTests = self.lib.mkTests;
          };
        }
      ) nixpkgs.legacyPackages;
    };
}
