/** @doc lib.mkTests
## `lib.mkTests`

```nix
inputs.tests.lib.mkTests { inherit pkgs; } tests
```

Converts a test declaration into an attribute set of derivations suitable for
`checks.${system}`. Each `test` name becomes an attribute name. Cases containing
`vm.configure` use the NixOS VM backend; all other cases use the terminal
backend.

The `tests` argument is a function receiving `test` and returning a list of
cases:

```nix
{ test, ... }:
[
  (test "example" ({ terminal, expect, ... }: [
    (terminal.open "example")
    ((expect (terminal.getByText "ready")).toBeVisible)
  ]))
]
```
*/
{ pkgs }:
tests:
let
  fixtures = import ./fixtures.nix;
  terminal = (import ../overlay.nix pkgs pkgs).testers.tui;
  /** @doc test
  ## `test`

  ```nix
  test name callback
  ```

  Declares one named test case. `callback` receives the `terminal`, `workspace`,
  `vm`, and `expect` fixtures and returns an ordered list of actions. The name is
  preserved as the check attribute, including spaces.
  */
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
