{
  lib,
  pkgs,
  fixtureFactories ? { },
  locators ? { },
  matcherFactories ? { },
}:
let
  builders = import ./builders.nix;
  moduleArgs = {
    inherit lib pkgs;
  } // builders;
  terminalInterface = import ../terminal/interface.nix { inherit lib; };
  terminalModule = import ../terminal/fixture.nix {
    inherit lib;
    inherit (builders) mkAction mkFixture;
  };
  machineModule = import ../machine/fixture.nix {
    inherit lib pkgs;
    inherit (builders) mkAction mkFixture;
  };
  fixtureModules = map (path: import path moduleArgs) [
    ../browser/fixture.nix
    ../container/fixture.nix
    ../desktop/fixture.nix
    ../filesystem/fixture.nix
    ../http/fixture.nix
    ../network/fixture.nix
    ../result/fixture.nix
    ../service/fixture.nix
    ../user/fixture.nix
  ];
  workspaceModule = import ../workspace/fixture.nix {
    inherit lib pkgs;
    inherit (builders) mkAction mkFixture;
  };
  terminalLocators = import ../terminal/locators.nix {
    inherit (builders) mkLocator;
  };
  machineLocators = import ../machine/locators.nix {
    inherit lib;
    inherit (builders) mkAction mkLocator;
  };
  builtInLocators = {
    inherit (terminalLocators.testing.locators) terminal;
    inherit (machineLocators.testing.locators) machine;
  };
  allLocators = lib.recursiveUpdate builtInLocators locators;
  builtInFixtureFactories = {
    inherit (terminalModule.testing.fixtures) terminal;
    inherit (machineModule.testing.fixtures) machine machines;
    inherit (workspaceModule.testing.fixtures) workspace;
  }
  // builtins.foldl' (acc: module: acc // module.testing.fixtures) { } fixtureModules;
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
  builtInMatcherFactories =
    terminalMatchers.testing.matchers
    // machineMatchers.testing.matchers
    // builtins.foldl' (acc: module: acc // module.testing.matchers) { } matcherModules;
  allMatcherFactories = builtInMatcherFactories // matcherFactories;
  makeExpect = (import ../expect/fixture.nix {
    matcherFactories = allMatcherFactories;
  }).make;
  allFixtureFactories = builtInFixtureFactories // fixtureFactories;
  unresolvedFixtures = builtins.mapAttrs (
    name: fixture:
    let
      value = fixture.factory fixtures;
      fixtureLocators = allLocators.${name} or { };
    in
    if builtins.isAttrs value then
      value // fixtureLocators
    else
      assert lib.assertMsg (fixtureLocators == { })
        "nix-test: non-attribute fixture '${name}' cannot own locators";
      value
  ) allFixtureFactories;
  bindMachine =
    node:
    node
    // {
      browser = unresolvedFixtures.browser.on node;
      service = name:
        let target = node.service name;
        in target // {
          start = unresolvedFixtures.service.start target;
          stop = unresolvedFixtures.service.stop target;
          restart = unresolvedFixtures.service.restart target;
          reload = unresolvedFixtures.service.reload target;
          logs = unresolvedFixtures.service.logs target;
        };
      container = name:
        let target = node.container name;
        in target // {
          start = unresolvedFixtures.container.start target;
          stop = unresolvedFixtures.container.stop target;
          restart = unresolvedFixtures.container.restart target;
          run = unresolvedFixtures.container.run target;
        };
      user = name:
        let target = node.user name;
        in target // {
          run = unresolvedFixtures.user.run target;
          service = serviceName:
            let serviceTarget = unresolvedFixtures.user.service target serviceName;
            in serviceTarget // {
              start = unresolvedFixtures.service.start serviceTarget;
              stop = unresolvedFixtures.service.stop serviceTarget;
              restart = unresolvedFixtures.service.restart serviceTarget;
              reload = unresolvedFixtures.service.reload serviceTarget;
              logs = unresolvedFixtures.service.logs serviceTarget;
            };
        };
    };
  fixtures = unresolvedFixtures // {
    expect = makeExpect fixtures;
    terminal = terminalInterface.implement "terminal" unresolvedFixtures.terminal;
    machine = bindMachine (terminalInterface.implement "machine" unresolvedFixtures.machine);
    machines = unresolvedFixtures.machines // {
      node = name: bindMachine (unresolvedFixtures.machines.node name);
    };
  };
in
fixtures
