/** @doc lib.mkTests
## `lib.mkTests`

```nix
inputs.tests.lib.mkTests {
  inherit pkgs test;
  fixtures = { };
  locators = { };
  matchers = { };
}
```

Converts an attribute set of test callbacks into derivations suitable for
`checks.${system}`. Attribute names become check names. `fixtures`, `locators`,
and `matchers` use the same plugin format as the flake-parts module and default
to empty attribute sets. Reserve `test.configure` for suite-wide defaults.
*/
{
  pkgs,
  test,
  fixtures ? { },
  locators ? { },
  matchers ? { },
}:
let
  builders = import ./builders.nix;
  terminal = (import ../overlay.nix pkgs pkgs).testers.tui;
  defaults = {
    timeout = 15;
    terminal = {
      columns = 140;
      rows = 42;
    };
  };
  configuration = pkgs.lib.recursiveUpdate defaults (test.configure or { });
  testCases = builtins.removeAttrs test [ "configure" ];
  allowedConfiguration = [ "timeout" "terminal" ];
  allowedTerminalConfiguration = [ "columns" "rows" ];
  unknownConfiguration = builtins.filter (
    name: !(builtins.elem name allowedConfiguration)
  ) (builtins.attrNames (test.configure or { }));
  unknownTerminalConfiguration = builtins.filter (
    name: !(builtins.elem name allowedTerminalConfiguration)
  ) (builtins.attrNames ((test.configure or { }).terminal or { }));
  builtInNames = [ "terminal" "workspace" "machine" "expect" ];
  terminalMatchers = import ../terminal/matchers.nix {
    inherit (builders) mkAction mkMatcher;
  };
  machineMatchers = import ../machine/matchers.nix {
    inherit (builders) mkAction mkMatcher;
  };
  builtInMatchers = builtins.attrNames (
    terminalMatchers.testing.matchers
    // machineMatchers.testing.matchers
  );
  fixtureCollisions = builtins.filter (name: builtins.hasAttr name fixtures) builtInNames;
  matcherCollisions = builtins.filter (name: builtins.hasAttr name matchers) builtInMatchers;
  unknownLocatorOwners = builtins.filter (
    name: !(builtins.elem name builtInNames) && !(builtins.hasAttr name fixtures)
  ) (builtins.attrNames locators);
  invalidFixtures = builtins.filter (
    name:
    let
      fixture = fixtures.${name};
    in
    !builtins.isAttrs fixture || (fixture._kind or null) != "fixture"
  ) (builtins.attrNames fixtures);
  testFixtures = import ./fixtures.nix {
    inherit pkgs;
    inherit (pkgs) lib;
    fixtureFactories = fixtures;
    inherit locators;
    matcherFactories = matchers;
  };
  cases = builtins.mapAttrs (
    name: callback:
    let
      arguments = builtins.functionArgs callback;
      requested = builtins.attrNames arguments;
      unknown = builtins.filter (
        fixture: !(builtins.hasAttr fixture testFixtures) && !arguments.${fixture}
      ) requested;
    in
    assert pkgs.lib.assertMsg (unknown == [ ])
      "nix-testing: test '${name}' requests unknown fixtures: ${builtins.concatStringsSep ", " unknown}";
    {
      inherit name;
      actions = callback (builtins.intersectAttrs (builtins.functionArgs callback) testFixtures);
    }
  ) testCases;
  invalidCases = builtins.filter (
    name:
    let
      actions = cases.${name}.actions;
    in
    !builtins.isList actions
    || !(builtins.all (action: builtins.isAttrs action && (action._kind or null) == "action") actions)
  ) (builtins.attrNames cases);
in
assert pkgs.lib.assertMsg (unknownConfiguration == [ ])
  "nix-testing: unknown test.configure options: ${builtins.concatStringsSep ", " unknownConfiguration}";
assert pkgs.lib.assertMsg (unknownTerminalConfiguration == [ ])
  "nix-testing: unknown test.configure.terminal options: ${builtins.concatStringsSep ", " unknownTerminalConfiguration}";
assert pkgs.lib.assertMsg (builtins.isInt configuration.timeout && configuration.timeout > 0)
  "nix-testing: test.configure.timeout must be a positive integer";
assert pkgs.lib.assertMsg (builtins.isInt configuration.terminal.columns && configuration.terminal.columns > 0)
  "nix-testing: test.configure.terminal.columns must be a positive integer";
assert pkgs.lib.assertMsg (builtins.isInt configuration.terminal.rows && configuration.terminal.rows > 0)
  "nix-testing: test.configure.terminal.rows must be a positive integer";
assert pkgs.lib.assertMsg (fixtureCollisions == [ ])
  "nix-testing: custom fixtures cannot replace built-ins: ${builtins.concatStringsSep ", " fixtureCollisions}";
assert pkgs.lib.assertMsg (invalidFixtures == [ ])
  "nix-testing: custom fixtures must be created with lib.mkFixture: ${builtins.concatStringsSep ", " invalidFixtures}";
assert pkgs.lib.assertMsg (matcherCollisions == [ ])
  "nix-testing: custom matchers cannot replace built-ins: ${builtins.concatStringsSep ", " matcherCollisions}";
assert pkgs.lib.assertMsg (unknownLocatorOwners == [ ])
  "nix-testing: locators reference unknown fixtures: ${builtins.concatStringsSep ", " unknownLocatorOwners}";
assert pkgs.lib.assertMsg (invalidCases == [ ])
  "nix-testing: tests must return only actions created with lib.mkAction: ${builtins.concatStringsSep ", " invalidCases}";
builtins.mapAttrs (
  name: case:
  if builtins.any (action: action.type == "machineConfigure") case.actions then
    pkgs.testers.runNixOSTest {
      inherit name;
      nodes.machine.imports = builtins.concatMap (action: action.modules) (
        builtins.filter (action: action.type == "machineConfigure") case.actions
      );
      testScript = ''
        machine.start()
        with subtest(${builtins.toJSON name}):
        ${pkgs.lib.concatMapStringsSep "\n" (action: "  " + action.code) (
          builtins.filter (action: action.type != "machineConfigure") case.actions
        )}
      '';
    }
  else
    terminal {
      inherit name;
      inherit (configuration) timeout;
      inherit (configuration.terminal) columns rows;
      tests = { test, ... }: [
        (test name (_: case.actions))
      ];
    }
) cases
