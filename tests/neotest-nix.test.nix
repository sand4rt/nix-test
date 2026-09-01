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
      inherit (inputs) nvf;
      neotestNix = inputs.self.packages.${system}.neotest-nix;

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
                plenary-nvim.package = pkgs.vimPlugins.plenary-nvim;
                neotest-nix = {
                  package = neotestNix;
                  after = [
                    "neotest"
                    "nvim-nio"
                    "plenary-nvim"
                  ];
                  setup = ''
                    require("neotest").setup({
                      output = {
                        open_on_run = false,
                      },
                      adapters = {
                        require("neotest-nix"),
                      },
                    })
                  '';
                };
              };
              keymaps = [
                {
                  key = "<leader>ts";
                  mode = "n";
                  action = ":lua local path = vim.api.nvim_buf_get_name(0); local summary = require('neotest').summary; summary.close(); summary.open({ enter = true }); summary:expand(path, true)<CR>";
                }
                {
                  key = "<leader>tr";
                  mode = "n";
                  lua = true;
                  action = /* lua */ ''
                    function()
                       local neotest = require("neotest")
                       local names = {}

                       for _, id in ipairs(neotest.state.adapter_ids()) do
                         local tree = neotest.state.positions(id)
                        if tree then
                          for _, position in tree:iter() do
                             local data = position
                             if data.type == "test" then
                               table.insert(names, data.name)
                             end
                           end
                         end
                       end

                       table.sort(names)
                       vim.api.nvim_echo({ {
                         "DISCOVERED: " .. table.concat(names, ", "),
                       } }, false, {})
                    end
                  '';
                }
              ];
            };
          }
        ];
      }).neovim;
    in
    {
      test."first project test" = { terminal }: {
        test.step."opens the program" = [
          terminal.print
        ];
        test.step."observes its output" = [
          terminal.print
        ];
      };

      test."second project test" = { terminal }: [
        terminal.print
      ];

      test."opens neotest summary" =
        {
          terminal,
          filesystem,
        }:
        [
          (filesystem.writeFile "flake.nix" /* nix */ ''
            { outputs = { self }: { }; }
          '')
          (filesystem.writeFile "project.test.nix" /* nix */ ''
            {
              test."first project test" = { terminal }: {
                test.step."opens the program" = [
                  terminal.print
                ];
                test.step."observes its output" = [
                  terminal.print
                ];
              };

              test."second project test" = { terminal }: [
                terminal.print
              ];
            }
          '')
          (terminal.open "env PATH=${
            pkgs.lib.makeBinPath [
              pkgs.nix
              pkgs.git
            ]
          } ${pkgs.lib.getExe neovim} ${filesystem.root}/project.test.nix")
          (expect (terminal.getByText "project.test.nix")).toBeVisible
          (terminal.press "<leader>ts")
          (expect (terminal.getByText "neotest-nix  2")).toBeVisible
          (terminal.press "<leader>tr")
          (expect (terminal.getByText "DISCOVERED: first project test, second project test")).toBeVisible
        ];
    };
}
