{ pkgs }:
tests:
let
  fixtures = import ./fixtures.nix;
  terminal = (import ../overlay.nix pkgs pkgs).testers.tui;
  cases = tests {
    test = name: callback: {
      inherit name;
      actions = callback fixtures;
    };
  };
in
builtins.listToAttrs (
  builtins.map (case: {
    name = case.name;
    value =
      if builtins.any (action: action.type == "vmConfigure") case.actions then
        builtins.getAttr case.name ((import ./vm/mk-tests.nix) {
          inherit pkgs;
          runner = pkgs.testers.runNixOSTest;
          cases = [ case ];
        })
      else
        terminal {
          inherit (case) name;
          tests = { test, ... }: [
            (test case.name (_: case.actions))
          ];
        };
  }) cases
)
