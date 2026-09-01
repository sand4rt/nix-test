{
  description = "A declarative testing framework for testing user-facing behavior in Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nvf = {
    url = "github:NotAShelf/nvf";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.neotest-nix = {
    url = "github:khaneliman/neotest-nix";
    flake = false;
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
          { pkgs, expect, ... }:
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
              ./tests/readme.test.nix
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
              "interop passes" = { terminal }: [
                (terminal.open pkgs.hello)
                (expect (terminal.getByText "Hello")).toBeVisible
              ];
            };
          };
      };
    in
    {
      flakeModules.default = import ./module.nix;
      lib =
        let
          builders = import ./core/builders.nix;
        in
        {
          inherit (builders) mkFixture mkLocator mkMatcher;
          /**
            @doc lib.test.step
            ## `lib.test.step`

            Plain-flake callers use `lib.test.step name actions` to create named
            steps. Flake-parts users receive the same function as `test.step`.
          */
          test = import ./step/fixture.nix builders;
          /**
            @doc lib.fixtures
            ## `lib.fixtures`

            ```nix
            inputs.tests.lib.fixtures { inherit pkgs; }
            ```

            Resolves the complete built-in fixture set for advanced integrations.
            Most projects should use `lib.mkTests` or the flake-parts module instead.
          */
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
              rm -f docs/src/reference/{core,terminal,fixtures,assertions}.md
              cp ${generatedApi.core} docs/src/reference/core.md
              cp ${generatedApi.terminal} docs/src/reference/terminal.md
              cp ${generatedApi.fixtures} docs/src/reference/fixtures.md
              cp ${generatedApi.assertions} docs/src/reference/assertions.md
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
                cmp docs/src/reference/fixtures.md ${generatedApi.fixtures}
                cmp docs/src/reference/assertions.md ${generatedApi.assertions}
              mkdir -p "$out"
              mdbook build --dest-dir "$out"
              runHook postBuild
            '';
            dontInstall = true;
          };
          neotest-nix = pkgs.vimUtils.buildVimPlugin {
            pname = "neotest-nix";
            version = "unstable";
            src = inputs.neotest-nix;
            patches = [ ./patches/neotest-nix-nix-test-kind.patch ];
            doCheck = false;
          };
        in
        {
          inherit docs generateDocs neotest-nix;
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
          api-unit = import ./core/api.test.nix {
            inherit pkgs;
            publicLib = self.lib;
            hasOverlay = self ? overlays;
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
