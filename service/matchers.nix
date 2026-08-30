{
  lib,
  mkAction,
  mkMatcher,
  ...
}:
let
  assertion = target: command: mkAction "machinePredicate" {
    inherit (target) node description;
    inherit command;
  };
  systemctl = target:
    if target.scope == "system" then
      "systemctl"
    else
      "systemctl --user -M ${lib.escapeShellArg "${target.user}@"}";
in
{
  testing.matchers = {
    toBeActive = mkMatcher {
      accepts = [ "service" ];
      run = _fixtures: target:
        assertion target "${systemctl target} is-active ${lib.escapeShellArg target.name}";
    };
    toBeInactive = mkMatcher {
      accepts = [ "service" ];
      run = _fixtures: target: assertion target (
        "test \"$(${systemctl target} is-active ${lib.escapeShellArg target.name})\" = inactive"
      );
    };
    toBeFailed = mkMatcher {
      accepts = [ "service" ];
      run = _fixtures: target: assertion target (
        "test \"$(${systemctl target} is-active ${lib.escapeShellArg target.name})\" = failed"
      );
    };
    toHaveLog = fixtures: target: text:
      fixtures.expect.toContain (fixtures.service.logs target) text;
    toContain = fixtures: target: text:
      assert builtins.elem target.type [ "serviceLogs" "machineCommand" ];
      assertion target "${target.command} | grep -F -- ${lib.escapeShellArg text}";
    toSucceed = mkMatcher {
      accepts = [ "machineCommand" ];
      run = _fixtures: target: assertion target target.command;
    };
  };
}
