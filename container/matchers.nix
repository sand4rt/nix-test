{
  lib,
  mkAction,
  mkMatcher,
  ...
}:
let
  assertion = target: comparison: mkAction "machinePredicate" {
    inherit (target) node description;
    command = "test \"$(nixos-container status ${lib.escapeShellArg target.name})\" ${comparison} RUNNING";
  };
in
{
  testing.matchers = {
    toBeRunning = mkMatcher {
      accepts = [ "container" ];
      run = _fixtures: target: assertion target "=";
    };
    toBeStopped = mkMatcher {
      accepts = [ "container" ];
      run = _fixtures: target: assertion target "!=";
    };
  };
}
