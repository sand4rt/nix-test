{
  lib,
  pkgs,
  fixtureFactories ? { },
  locators ? { },
  matcherFactories ? { },
}:
let
  builders = import ./builders.nix;
  terminalInterface = import ../terminal/interface.nix { inherit lib; };
  terminalModule = import ../terminal/fixture.nix {
    inherit lib;
    inherit (builders) mkAction mkFixture;
  };
  machineModule = import ../machine/fixture.nix {
    inherit lib pkgs;
    inherit (builders) mkAction mkFixture;
  };
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
    inherit (machineModule.testing.fixtures) machine;
    inherit (workspaceModule.testing.fixtures) workspace;
    expect = builders.mkFixture (
      fixtures: builtins.mapAttrs (_: factory: factory fixtures) allMatcherFactories
    );
  };
  terminalMatchers = import ../terminal/matchers.nix {
    inherit (builders) mkAction mkMatcher;
  };
  machineMatchers = import ../machine/matchers.nix {
    inherit (builders) mkAction mkMatcher;
  };
  builtInMatcherFactories = terminalMatchers.testing.matchers // machineMatchers.testing.matchers;
  allMatcherFactories = builtInMatcherFactories // matcherFactories;
  allFixtureFactories = builtInFixtureFactories // fixtureFactories;
  unresolvedFixtures = builtins.mapAttrs (
    name: fixture: fixture.factory fixtures // (allLocators.${name} or { })
  ) allFixtureFactories;
  fixtures = unresolvedFixtures // {
    terminal = terminalInterface.implement "terminal" unresolvedFixtures.terminal;
    machine = terminalInterface.implement "machine" unresolvedFixtures.machine;
  };
in
fixtures
