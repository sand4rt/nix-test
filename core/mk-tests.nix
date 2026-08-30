/**
  @doc lib.mkTests
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
  moduleArgs = {
    inherit pkgs;
    inherit (pkgs) lib;
  } // builders;
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
  allowedConfiguration = [
    "timeout"
    "terminal"
  ];
  allowedTerminalConfiguration = [
    "columns"
    "rows"
  ];
  unknownConfiguration = builtins.filter (name: !(builtins.elem name allowedConfiguration)) (
    builtins.attrNames (test.configure or { })
  );
  unknownTerminalConfiguration = builtins.filter (
    name: !(builtins.elem name allowedTerminalConfiguration)
  ) (builtins.attrNames ((test.configure or { }).terminal or { }));
  builtInNames = [
    "terminal"
    "workspace"
    "machine"
    "machines"
    "expect"
    "service"
    "filesystem"
    "network"
    "http"
    "user"
    "container"
    "browser"
    "desktop"
    "result"
  ];
  terminalMatchers = import ../terminal/matchers.nix {
    inherit (builders) mkAction mkMatcher;
  };
  machineMatchers = import ../machine/matchers.nix {
    inherit (builders) mkAction mkMatcher;
  };
  matcherModules = map (path: import path moduleArgs) [
    ../browser/matchers.nix
    ../container/matchers.nix
    ../desktop/matchers.nix
    ../filesystem/matchers.nix
    ../http/matchers.nix
    ../network/matchers.nix
    ../result/matchers.nix
    ../service/matchers.nix
    ../user/matchers.nix
  ];
  builtInMatchers = builtins.attrNames (
    terminalMatchers.testing.matchers
    // machineMatchers.testing.matchers
    // builtins.foldl' (acc: module: acc // module.testing.matchers) { } matcherModules
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
    assert pkgs.lib.assertMsg (
      unknown == [ ]
    ) "nix-test: test '${name}' requests unknown fixtures: ${builtins.concatStringsSep ", " unknown}";
    {
      inherit name;
      actions = callback (builtins.intersectAttrs (builtins.functionArgs callback) testFixtures);
    }
  ) testCases;
  invalidCases = builtins.filter (
    name:
    let
      actions = cases.${name}.actions;
      validAction =
        action:
        builtins.isAttrs action
        && (action._kind or null) == "action"
        && builtins.isString (action.type or null)
        && (
          action.type != "step"
          || (
            builtins.isString (action.name or null)
            && builtins.isList (action.actions or null)
            && builtins.all validAction action.actions
          )
        );
    in
    !builtins.isList actions
    || !(builtins.all validAction actions)
  ) (builtins.attrNames cases);
  machineActionTypes = [
    "browserAction"
    "browserAssertion"
    "browserConfigure"
    "containerAction"
    "desktopAction"
    "desktopAssertion"
    "machineAssertion"
    "machineCommand"
    "machineLifecycle"
    "machinePredicate"
    "machineResult"
    "networkHeal"
    "networkPartition"
    "resultAssertion"
    "serviceAction"
    "userCommand"
  ];
  flattenActions =
    actions:
    builtins.concatMap (
      action: [ action ] ++ (if action.type == "step" then flattenActions action.actions else [ ])
    ) actions;
  missingMachineConfigurations = builtins.filter (
    name:
    let
      actions = flattenActions cases.${name}.actions;
    in
    !(builtins.any (action: action.type == "machineConfigure") actions)
    && builtins.any (action: builtins.elem action.type machineActionTypes) actions
  ) (builtins.attrNames cases);
  renderAction =
    action:
    if action.type == "machinePredicate" then
      let
        machine = "machines[${builtins.toJSON action.node}]";
      in
      "${machine}.wait_until_succeeds(${builtins.toJSON action.command}, timeout=${toString configuration.timeout})"
    else
      action.code;
  renderActions =
    indent: actions:
    pkgs.lib.concatMapStringsSep "\n" (
      action:
      if action.type == "machineConfigure" then
        ""
      else if action.type == "step" then
        "${indent}with subtest(${builtins.toJSON action.name}):\n${renderActions "${indent}  " action.actions}"
      else
        pkgs.lib.concatMapStringsSep "\n" (line: indent + line) (
          pkgs.lib.splitString "\n" (renderAction action)
        )
    ) actions;
  machineConfigurations =
    actions: builtins.filter (action: action.type == "machineConfigure") actions;
  configuredNodes =
    actions:
    pkgs.lib.foldl' (
      nodes: action:
      pkgs.lib.foldlAttrs (
        result: name: options:
        result
        // {
          ${name}.modules = (result.${name}.modules or [ ]) ++ options.modules;
        }
      ) nodes action.nodes
    ) { } (machineConfigurations actions);
  workspaceActionTypes = [
    "copyFile"
    "copyTree"
    "makeDirectory"
    "removePath"
    "setMode"
    "symlink"
    "writeFile"
  ];
  invalidNamedMachineWorkspaces = builtins.filter (
    name:
    let
      actions = flattenActions cases.${name}.actions;
      nodes = configuredNodes actions;
    in
    actions != [ ]
    && builtins.any (action: builtins.elem action.type workspaceActionTypes) actions
    && builtins.any (action: action.type == "machineConfigure") actions
    && !(builtins.hasAttr "machine" nodes)
  ) (builtins.attrNames cases);
  browserConfigurations =
    actions: builtins.filter (action: action.type == "browserConfigure") actions;
in
assert pkgs.lib.assertMsg (unknownConfiguration == [ ])
  "nix-test: unknown test.configure options: ${builtins.concatStringsSep ", " unknownConfiguration}";
assert pkgs.lib.assertMsg (unknownTerminalConfiguration == [ ])
  "nix-test: unknown test.configure.terminal options: ${builtins.concatStringsSep ", " unknownTerminalConfiguration}";
assert pkgs.lib.assertMsg (
  builtins.isInt configuration.timeout && configuration.timeout > 0
) "nix-test: test.configure.timeout must be a positive integer";
assert pkgs.lib.assertMsg (
  builtins.isInt configuration.terminal.columns && configuration.terminal.columns > 0
) "nix-test: test.configure.terminal.columns must be a positive integer";
assert pkgs.lib.assertMsg (
  builtins.isInt configuration.terminal.rows && configuration.terminal.rows > 0
) "nix-test: test.configure.terminal.rows must be a positive integer";
assert pkgs.lib.assertMsg (fixtureCollisions == [ ])
  "nix-test: custom fixtures cannot replace built-ins: ${builtins.concatStringsSep ", " fixtureCollisions}";
assert pkgs.lib.assertMsg (invalidFixtures == [ ])
  "nix-test: custom fixtures must be created with lib.mkFixture: ${builtins.concatStringsSep ", " invalidFixtures}";
assert pkgs.lib.assertMsg (matcherCollisions == [ ])
  "nix-test: custom matchers cannot replace built-ins: ${builtins.concatStringsSep ", " matcherCollisions}";
assert pkgs.lib.assertMsg (unknownLocatorOwners == [ ])
  "nix-test: locators reference unknown fixtures: ${builtins.concatStringsSep ", " unknownLocatorOwners}";
assert pkgs.lib.assertMsg (invalidCases == [ ])
  "nix-test: tests must return only actions created with lib.mkAction: ${builtins.concatStringsSep ", " invalidCases}";
assert pkgs.lib.assertMsg (missingMachineConfigurations == [ ])
  "nix-test: machine actions require machine.configure or machines.configure: ${builtins.concatStringsSep ", " missingMachineConfigurations}";
assert pkgs.lib.assertMsg (invalidNamedMachineWorkspaces == [ ])
  "nix-test: workspace actions in machine tests require the default machine; named-machine workspace staging is not yet supported: ${builtins.concatStringsSep ", " invalidNamedMachineWorkspaces}";
builtins.mapAttrs (
  name: case:
  if builtins.any (action: action.type == "machineConfigure") (flattenActions case.actions) then
    let
      actions = case.actions;
      flatActions = flattenActions actions;
      nodes = configuredNodes flatActions;
      browsers = browserConfigurations flatActions;
    in
    pkgs.testers.runNixOSTest {
      inherit name;
      skipTypeCheck = true;
      nodes = builtins.mapAttrs (_: options: {
        imports = [
          {
            environment.systemPackages = [
              pkgs.curl
              pkgs.iptables
              pkgs.jq
              pkgs.netcat
              pkgs.tmux
            ];
          }
        ]
        ++ options.modules;
      }) nodes;
      extraPythonPackages = pythonPackages: pkgs.lib.optional (browsers != [ ]) pythonPackages.selenium;
      testScript = ''
        timeout = ${toString configuration.timeout}
        browsers = {}
        results = {}
        try:
          start_all()
          machines = {machine.name: machine for machine in machines}
          with subtest(${builtins.toJSON name}):
        ${renderActions "    " actions}
        finally:
          for browser in browsers.values():
            browser.quit()
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
