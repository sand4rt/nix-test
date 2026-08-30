{ ... }:
{
  nixpkgs.overlays = [ (import ./overlay.nix) ];
  _module.args.tests = inputs.tests;
}
