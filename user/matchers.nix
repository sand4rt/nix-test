{
  lib,
  mkAction,
  ...
}:
{
  testing.matchers.toBeMemberOf = fixtures: target: group: mkAction "machinePredicate" {
    inherit (target) node description;
    command = "id -nG ${lib.escapeShellArg target.name} | tr ' ' '\\n' | grep -Fx ${lib.escapeShellArg group}";
  };
}
