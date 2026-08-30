{
  lib,
  pkgs,
  mkAction,
  ...
}:
let
  assertion = target: command: mkAction "machinePredicate" {
    inherit (target) node description;
    inherit command;
  };
  curlCommand = target: extra: lib.concatStringsSep " " (
    [
      (lib.getExe pkgs.curl)
      "--silent"
      "--show-error"
      "--location"
      "--request"
      target.method
    ]
    ++ lib.optional (target.body != null) "--data ${lib.escapeShellArg target.body}"
    ++ lib.optional (target.headers != { }) (lib.concatStringsSep " " (
      lib.mapAttrsToList (name: value: "-H ${lib.escapeShellArg "${name}: ${value}"}") target.headers
    ))
    ++ [ extra (lib.escapeShellArg target.url) ]
  );
in
{
  testing.matchers = {
    toHaveStatus = fixtures: expected: target:
      assertion target (
        curlCommand target "--output /dev/null --write-out '%{http_code}'"
        + " | grep -Fx ${lib.escapeShellArg (toString expected)}"
      );
    toHaveBody = fixtures: target: expected:
      assertion target (curlCommand target "" + " | grep -F -- ${lib.escapeShellArg expected}");
    toHaveHeader = fixtures: target: { name, value }:
      assertion target (
        curlCommand target "--head" + " | grep -iFx -- ${lib.escapeShellArg "${name}: ${value}"}"
      );
    toHaveJsonValue = fixtures: { actual, path, expected }:
      assertion actual (
        curlCommand actual "" + " | ${lib.getExe pkgs.jq} -e --argjson expected ${lib.escapeShellArg (builtins.toJSON expected)} "
        + lib.escapeShellArg ".${path} == \$expected"
      );
  };
}
