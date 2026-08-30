{
  description = "Minimal Playwright-style TUI tests for Nix";

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
        {
          runner = pkgs.writeText "tui-test-runner.py" (import ./lib/runner.nix);
        }
      ) nixpkgs.legacyPackages;
    };
}
