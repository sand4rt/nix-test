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
  (expect container).toBeRunning
  (expect container).toBeStopped
  ```
*/
let
  assertion = target: command: mkAction "machinePredicate" {
    inherit (target) node description;
    inherit command;
  };
  isActive = target:
    "systemctl is-active --quiet container@${lib.escapeShellArg target.name}.service";
in
{
  testing.matchers = {
    toBeRunning = mkMatcher {
      accepts = [ "container" ];
      run = _fixtures: target: assertion target (isActive target);
    };
    toBeStopped = mkMatcher {
      accepts = [ "container" ];
      run = _fixtures: target: assertion target "! ${isActive target}";
    };
  };
}
