{
  pkgs,
  publicLib,
  hasOverlay,
}:
assert builtins.attrNames publicLib == [
  "fixtures"
  "mkFixture"
  "mkLocator"
  "mkMatcher"
  "mkTests"
  "test"
];
assert builtins.attrNames publicLib.test == [ "step" ];
assert !hasOverlay;
pkgs.runCommand "nix-test-api-unit" { } ''
  touch "$out"
''
