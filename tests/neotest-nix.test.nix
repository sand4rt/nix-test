{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      expect,
      ...
    }:
    let
      inherit (inputs)
        self
        nixpkgs
        flake-parts
        neotest-nix
        nvf
        ;

      targetCheck =
        let
          inherit (self.lib.fixtures { inherit pkgs; }) terminal expect;
        in
        (self.lib.mkTests {
          inherit pkgs;
          test."interop passes" = { terminal }: [
            (terminal.open pkgs.hello)
            (expect (terminal.getByText "Hello")).toBeVisible
          ];
        })."interop passes";

      frameworkFlakeDefinition = pkgs.writeText "flake.nix" ''
        {
          inputs = {
            nixpkgs.url = "path:${nixpkgs}";
            flake-parts = {
              url = "path:${flake-parts}";
              inputs.nixpkgs-lib.follows = "nixpkgs";
            };
          };

          outputs = { nixpkgs, ... }: {
            flakeModules.default = import ./module.nix;
            lib = (import ./core/builders.nix) // {
              fixtures = { pkgs }: import ./core/fixtures.nix {
                inherit (pkgs) lib;
              };
              mkTests = import ./core/mk-tests.nix;
            };
          };
        }
      '';

      frameworkFlake = pkgs.runCommand "nix-test-public-flake" { } ''
        cp -R ${self} "$out"
        chmod -R u+w "$out"
        cp ${frameworkFlakeDefinition} "$out/flake.nix"
        rm -f "$out/flake.lock"
      '';

      fixtureTest = pkgs.writeText "fixture.test.nix" ''
        { pkgs, expect, ... }:
        {
          test."interop passes" = { terminal }: [
            (terminal.open pkgs.hello)
            (expect (terminal.getByText "Hello")).toBeVisible
          ];
        }
      '';

      fixtureFlake = pkgs.writeText "flake.nix" ''
        {
          inputs = {
            nixpkgs.url = "path:${nixpkgs}";
            flake-parts = {
              url = "path:${flake-parts}";
              inputs.nixpkgs-lib.follows = "nixpkgs";
            };
            tests = {
              url = "path:${frameworkFlake}";
              inputs.nixpkgs.follows = "nixpkgs";
              inputs.flake-parts.follows = "flake-parts";
            };
          };

          outputs = inputs:
            inputs.flake-parts.lib.mkFlake { inherit inputs; } {
              imports = [ inputs.tests.flakeModules.default ];
              systems = [ "${system}" ];
              perSystem = { ... }: {
                imports = [ ./fixture.test.nix ];
              };
            };
        }
      '';

      neovim =
        let
          neotestNix = pkgs.vimUtils.buildVimPlugin {
            pname = "neotest-nix";
            version = "unstable";
            src = neotest-nix;
            doCheck = false;
          };
        in
        (nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [
            {
              config.vim = {
                extraPackages = [ pkgs.nix ];
                treesitter = {
                  enable = true;
                  grammars = [ pkgs.vimPlugins.nvim-treesitter.grammarPlugins.nix ];
                };
                extraPlugins.neotest.package = pkgs.vimPlugins.neotest;
                extraPlugins.nvim-nio.package = pkgs.vimPlugins.nvim-nio;
                extraPlugins.neotest-nix = {
                  package = neotestNix;
                  after = [
                    "neotest"
                    "nvim-nio"
                  ];
                  setup = ''
                    require("neotest").setup({
                      icons = {
                        child_indent = "  ",
                        child_prefix = "",
                        collapsed = "+",
                        expanded = "-",
                        failed = "F",
                        final_child_prefix = "",
                        non_collapsible = " ",
                        passed = "P",
                        running = "R",
                        skipped = "S",
                        unknown = "?",
                      },
                      adapters = {
                        require("neotest-nix")({
                          discover_eval_checks = true,
                        }),
                      },
                    })
                  '';
                };
              };
            }
          ];
        }).neovim;
    in
    {
      test."neotest-nix interoperability" = { machine, filesystem }: [
          (machine.configure {
            modules = [
              {
                nix.settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
                environment.systemPackages = [
                  neovim
                  pkgs.nix
                ];
                virtualisation.additionalPaths = [
                  self
                  frameworkFlake
                  nixpkgs
                  flake-parts
                  targetCheck
                  fixtureFlake
                  fixtureTest
                ];
              }
            ];
          })
          (filesystem.writeFile "flake.nix" (builtins.readFile fixtureFlake))
          (filesystem.writeFile "fixture.test.nix" (builtins.readFile fixtureTest))
          (machine.command ''
            cd ${filesystem.root}
            nix flake lock --offline
            nix eval --json --apply builtins.attrNames .#checks.${system}
          '')
          (machine.open "cd ${filesystem.root} && nvim flake.nix")
          (machine.press ":lua require('neotest').summary.open()")
          (machine.press "<enter>")
          (expect (machine.getByText "flake.nix")).toBeVisible
          machine.print
      ];
    };
}
