{
  lib,
  pkgs,
  mkAction,
  mkMatcher,
  ...
}:
/**
  @doc assertions.network
  ## Network endpoints

  ```nix
  (expect endpoint).toBeReachable
  (expect endpoint).toBeUnreachable
  ```

  Endpoint observations retry until the configured timeout.
*/
let
  assertion = target: command: mkAction "machinePredicate" {
    inherit (target) node description;
    inherit command;
  };
  reachable = target:
    if target.transport == "tcp" then
      "${lib.getExe pkgs.curl} --silent --fail --max-time 1 telnet://${target.host}:${toString target.port} </dev/null"
    else
      "${pkgs.netcat}/bin/nc -zu -w1 ${lib.escapeShellArg target.host} ${toString target.port}";
in
{
  testing.matchers = {
    toBeReachable = mkMatcher {
      accepts = [ "endpoint" ];
      run = _fixtures: target: assertion target (reachable target);
    };
    toBeUnreachable = mkMatcher {
      accepts = [ "endpoint" ];
      run = _fixtures: target: assertion target "! ${reachable target}";
    };
  };
}
