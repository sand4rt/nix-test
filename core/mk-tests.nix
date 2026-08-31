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

  Converts an attribute set of fixture callbacks into derivations suitable for
  `checks.${system}`. Attribute names become check names. `fixtures`, `locators`,
  and `matchers` use the same plugin format as the flake-parts module and default
  to empty attribute sets. Each test must be a callback that receives only the
  fixtures it requests. Reserve `test.configure` for suite-wide defaults.
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
  resolvedFixtures = import ./fixtures.nix {
    inherit pkgs;
    inherit (pkgs) lib;
    fixtureFactories = fixtures;
    inherit locators;
    matcherFactories = matchers;
  };
  testFixtures = builtins.removeAttrs resolvedFixtures [ "expect" ];
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
  unknownCaseFixtures = pkgs.lib.concatMap (
    name:
    let callback = testCases.${name};
    in
    if builtins.isFunction callback then
      map (fixture: "${name}: ${fixture}") (
        builtins.filter (fixture: !(builtins.hasAttr fixture testFixtures)) (
          builtins.attrNames (builtins.functionArgs callback)
        )
      )
    else
      [ ]
  ) (builtins.attrNames testCases);
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
    "machine"
    "machines"
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
  cases = builtins.mapAttrs (
    name: callback:
    {
      inherit name;
      actions =
        if builtins.isFunction callback then
          callback (builtins.intersectAttrs (builtins.functionArgs callback) testFixtures)
        else
          callback;
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
    !builtins.isFunction testCases.${name}
    || !builtins.isList actions
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
  hasMachineActions = actions:
    builtins.any (action: builtins.elem action.type machineActionTypes) actions;
  graphicalActionTypes = [
    "browserAction"
    "browserAssertion"
    "browserConfigure"
    "desktopAction"
    "desktopAssertion"
  ];
  hasGraphicalActions = actions:
    builtins.any (action: builtins.elem action.type graphicalActionTypes) actions;
  withTestMetadata = metadata: derivation:
    derivation // { nixTest = metadata; };
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
    let
      configured = pkgs.lib.foldl' (
        nodes: action:
        pkgs.lib.foldlAttrs (
          result: name: options:
          result
          // {
            ${name}.modules = (result.${name}.modules or [ ]) ++ options.modules;
          }
        ) nodes action.nodes
      ) { } (machineConfigurations actions);
      inferredNames = pkgs.lib.unique (
        pkgs.lib.concatMap (
          action:
          pkgs.lib.optional (action ? node) action.node
          ++ (action.left or [ ])
          ++ (action.right or [ ])
        ) actions
      );
    in
    if configured == { } then
      builtins.listToAttrs (
        map (name: {
          inherit name;
          value.modules = [ ];
        }) inferredNames
      )
    else
      configured;
  filesystemActionTypes = [
    "copyFile"
    "copyTree"
    "makeDirectory"
    "removePath"
    "setMode"
    "symlink"
    "writeFile"
  ];
  invalidNamedMachineFilesystems = builtins.filter (
    name:
    let
      actions = flattenActions cases.${name}.actions;
      nodes = configuredNodes actions;
    in
    actions != [ ]
    && builtins.any (action: builtins.elem action.type filesystemActionTypes) actions
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
assert pkgs.lib.assertMsg (unknownCaseFixtures == [ ])
  "nix-test: tests request unknown fixtures: ${builtins.concatStringsSep ", " unknownCaseFixtures}";
assert pkgs.lib.assertMsg (invalidCases == [ ])
  "nix-test: tests must return only actions created with lib.mkAction: ${builtins.concatStringsSep ", " invalidCases}";
assert pkgs.lib.assertMsg (invalidNamedMachineFilesystems == [ ])
  "nix-test: filesystem mutations in machine tests require the default machine; named-machine staging is not yet supported: ${builtins.concatStringsSep ", " invalidNamedMachineFilesystems}";
builtins.mapAttrs (
  name: case:
  if hasMachineActions (flattenActions case.actions) then
    let
      actions = case.actions;
      flatActions = flattenActions actions;
      nodes = configuredNodes flatActions;
      browsers = browserConfigurations flatActions;
    in
    withTestMetadata {
      backend = "machine";
      graphical = hasGraphicalActions flatActions;
    } (pkgs.testers.runNixOSTest {
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
    })
  else
    withTestMetadata {
      backend = "terminal";
      graphical = false;
    } (terminal {
      inherit name;
      inherit (configuration) timeout;
      inherit (configuration.terminal) columns rows;
      tests = { test, ... }: [
        (test name (_: case.actions))
      ];
    })
) cases
