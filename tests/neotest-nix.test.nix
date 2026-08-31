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
      inherit (inputs) neotest-nix nvf;

      neotestNix = pkgs.vimUtils.buildVimPlugin {
        pname = "neotest-nix";
        version = "unstable";
        src = neotest-nix;
        doCheck = false;
      };

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
              extraPlugins = {
                neotest.package = pkgs.vimPlugins.neotest;
                nvim-nio.package = pkgs.vimPlugins.nvim-nio;
                neotest-nix = {
                  package = neotestNix;
                  after = [
                    "neotest"
                    "nvim-nio"
                  ];
                  setup = ''
                    require("neotest").setup({
                      adapters = {
                        require("neotest-nix")({
                          discover_eval_checks = true,
                        }),
                      },
                    })
                  '';
                };
              };
              keymaps = [
                {
                  key = "<leader>ts";
                  mode = "n";
                  action = ":lua require('neotest').summary.open()<CR>";
                }
              ];
            };
          }
        ];
      }).neovim;
    in
    {
      test."opens neotest summary" =
        {
          terminal,
          filesystem,
        }:
        [
          (filesystem.writeFile "flake.nix" /* nix */ ''
            { outputs = { self }: {
              checks.${system} = {
                "first test" = builtins.storePath "${pkgs.writeText "first-test-result" "ok"}";
                "second test" = builtins.storePath "${pkgs.writeText "second-test-result" "ok"}";
              };
            }; }
          '')

          (terminal.open "env PATH=${
            pkgs.lib.makeBinPath [
              pkgs.nix
              pkgs.git
            ]
          } ${pkgs.lib.getExe neovim} ${filesystem.root}/flake.nix")
          (expect (terminal.getByText "flake.nix")).toBeVisible
          (terminal.press "<leader>ts")
          (expect (terminal.getByText "first test")).toBeVisible
          (expect (terminal.getByText "second test")).toBeVisible
        ];
    };
}
