# Running Tests

Every named test is exposed as a check for its system.

## Run One Test

```sh
nix build '.#checks.x86_64-linux."shows greeting"' --no-link -L
```

`--no-link` avoids creating a result symlink. `-L` streams the test log.

## Run All Tests

```sh
nix flake check
```

Use `nix flake show` to list generated check names.

## Without Flake-parts

Pass tests directly to `lib.mkTests`:

```nix
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in {
  checks.${system} = inputs.tests.lib.mkTests {
    inherit pkgs;
    test = (import ./tests/hello.test.nix { inherit pkgs; }).test;
  };
}
```

`fixtures` and `matchers` accept the same plugin values as their flake-parts
options.

## Without Flakes

With Nix Test available at a local path:

```nix
# tests.nix
{ pkgs ? import <nixpkgs> { }, nix-test ? ./vendor/nix-test }:
(import "${nix-test}/core/mk-tests.nix") {
  inherit pkgs;
  test = (import ./tests/hello.test.nix { inherit pkgs; }).test;
}
```

Run one test with:

```sh
nix-build tests.nix -A 'shows a greeting'
```

## Interactive Machine Tests

Machine checks expose the standard NixOS interactive driver:

```sh
nix build \
  '.#checks.x86_64-linux."service starts".driverInteractive' \
  -o result-driver
./result-driver/bin/nixos-test-driver
```

Continue with [Debugging](debugging.md) for VM shells, SSH, port forwarding, and
persistent machine state.

## Run From Neovim

[neotest-nix](https://github.com/khaneliman/neotest-nix) discovers Nix Test
declarations directly from `*.test.nix` files and maps each `test."name"` to
its generated `checks.${system}."name"` output. Tests can therefore be browsed
and run through [Neotest](https://github.com/nvim-neotest/neotest) without
redeclaring them in `flake.nix` or enabling evaluated check discovery.

With NVF, add the adapter and its dependencies:

```nix
{
  vim = {
    extraPackages = [ pkgs.nix ];

    treesitter = {
      enable = true;
      grammars = [ pkgs.vimPlugins.nvim-treesitter.grammarPlugins.nix ];
    };

    extraPlugins = {
      neotest.package = pkgs.vimPlugins.neotest;
      nvim-nio.package = pkgs.vimPlugins.nvim-nio;
      neotest-nix = {
        package = inputs.tests.packages.${system}.neotest-nix;
        after = [
          "neotest"
          "nvim-nio"
        ];
        setup = ''
          require("neotest").setup({
            adapters = {
              require("neotest-nix"),
            },
          })
        '';
      };
    };
  };
}
```

Open a `*.test.nix` file and Neotest's summary to browse its tests, then run one
test or the whole file with the usual Neotest commands. The package exported by
Nix Test applies the source-discovery patch until it is available in an upstream
neotest-nix release. See the
[neotest-nix repository](https://github.com/khaneliman/neotest-nix) for adapter
options and keymap examples.
