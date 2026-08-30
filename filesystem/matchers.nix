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
  pathTest = target: flag: assertion target "test ${flag} ${lib.escapeShellArg target.path}";
in
{
  testing.matchers = {
    toExist = mkMatcher {
      accepts = [ "path" "jsonFile" "user" ];
      run = _fixtures: target:
        if target.type == "user" then
          assertion target "getent passwd ${lib.escapeShellArg target.name} >/dev/null"
        else
          pathTest target "-e";
    };
    toBeAbsent = mkMatcher {
      accepts = [ "path" "jsonFile" "user" ];
      run = _fixtures: target:
        if target.type == "user" then
          assertion target "! getent passwd ${lib.escapeShellArg target.name} >/dev/null"
        else
          pathTest target "! -e";
    };
    toBeFile = mkMatcher {
      accepts = [ "path" ];
      run = _fixtures: target: pathTest target "-f";
    };
    toBeDirectory = mkMatcher {
      accepts = [ "path" ];
      run = _fixtures: target: pathTest target "-d";
    };
    toBeSymlink = mkMatcher {
      accepts = [ "path" ];
      run = _fixtures: target: pathTest target "-L";
    };
    toBeMounted = mkMatcher {
      accepts = [ "path" ];
      run = _fixtures: target: assertion target "mountpoint -q ${lib.escapeShellArg target.path}";
    };
    toHaveContent = fixtures: target: expected:
      assertion target "test \"$(cat ${lib.escapeShellArg target.path})\" = ${lib.escapeShellArg expected}";
    toPointTo = fixtures: target: expected:
      assertion target "test \"$(readlink ${lib.escapeShellArg target.path})\" = ${lib.escapeShellArg expected}";
    toHaveMode = fixtures: target: expected:
      assertion target "test \"$(stat -c %a ${lib.escapeShellArg target.path})\" = ${lib.escapeShellArg (lib.removePrefix "0" expected)}";
    toBeOwnedBy = fixtures: target: expected:
      assertion target "test \"$(stat -c %U ${lib.escapeShellArg target.path})\" = ${lib.escapeShellArg expected}";
  };
}
