{
  lib,
  mkAction,
  mkMatcher,
  ...
}:
/**
  @doc assertions.containers
  ## Containers

  ```nix
  expect.toBeRunning container
  expect.toBeStopped container
  ```
*/
let
  assertion = target: expected: mkAction "machinePredicate" {
    inherit (target) node description;
    command = "test \"$(nixos-container status ${lib.escapeShellArg target.name})\" = ${expected}";
  };
in
{
  testing.matchers = {
    toBeRunning = mkMatcher {
      accepts = [ "container" ];
      run = _fixtures: target: assertion target "RUNNING";
    };
    toBeStopped = mkMatcher {
      accepts = [ "container" ];
      run = _fixtures: target: assertion target "STOPPED";
    };
  };
}
