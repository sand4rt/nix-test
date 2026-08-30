{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      inherit (inputs) self nixpkgs flake-parts nvf;

      targetCheck = (self.lib.mkTests {
        inherit pkgs;
        test."interop passes" = { terminal, expect }: [
          (terminal.open pkgs.hello)
          (expect.toBeVisible (terminal.getByText "Hello"))
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

      frameworkFlake = pkgs.runCommand "nix-testing-public-flake" { } ''
        cp -R ${self} "$out"
        chmod -R u+w "$out"
        cp ${frameworkFlakeDefinition} "$out/flake.nix"
        rm -f "$out/flake.lock"
      '';

      fixtureTest = pkgs.writeText "fixture.test.nix" ''
        { pkgs, ... }:
        {
          test."interop passes" = { terminal, expect }: [
            (terminal.open pkgs.hello)
            (expect.toBeVisible (terminal.getByText "Hello"))
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

      neovim = (nvf.lib.neovimConfiguration {
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
                package = pkgs.vimPlugins.neotest-nix;
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
      test."neotest-nix interoperability" = { machine, workspace, expect }: [
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
        (workspace.writeFile "flake.nix" (builtins.readFile fixtureFlake))
        (workspace.writeFile "fixture.test.nix" (builtins.readFile fixtureTest))
        (machine.command ''
          cd ${workspace.path}
          nix flake lock --offline
          nix eval --json --apply builtins.attrNames .#checks.${system}
        '')
        (machine.open "cd ${workspace.path} && nvim flake.nix")
        (machine.press ":lua require('neotest').summary.open()")
        (machine.press "<enter>")
        (expect.toBeVisible (machine.getByText "flake.nix"))
        (machine.press "<c-w>")
        (machine.press "o")
        (machine.press "/flake.nix")
        (machine.press "<enter>")
        (machine.press "e")
        (expect.toBeVisible (machine.getByText "checks"))
        (machine.press "/checks")
        (machine.press "<enter>")
        (machine.press "e")
        (expect.toBeVisible (machine.getByText "${system}"))
        (machine.press "/${system}")
        (machine.press "<enter>")
        (machine.press "e")
        (expect.toBeVisible (machine.getByText "interop passes"))
        (expect.toEqual {
          actual = machine.getByRegion {
            width = 40;
            height = 5;
          };
          expected = ''
            neotest-nix
            - flake.nix (tmp/nix-testing)
              - checks
                - ${system}
                    interop passes
          '';
        })
        machine.print
        (machine.press "/interop passes")
        (machine.press "<enter>")
        (machine.press "r")
        (expect.toBeVisible (machine.getByPattern "P.*interop passes"))
      ];
    };
}
