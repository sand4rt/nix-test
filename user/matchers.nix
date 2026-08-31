{
  lib,
  mkAction,
  ...
}:
/**
  @doc assertions.users
  ## Users

  ```nix
  (expect user).toBeMemberOf group
  ```

  Use `toExist` and `toBeAbsent` for user existence.
*/
{
  testing.matchers.toBeMemberOf = fixtures: target: group: mkAction "machinePredicate" {
    inherit (target) node description;
    command = "id -nG ${lib.escapeShellArg target.name} | tr ' ' '\\n' | grep -Fx ${lib.escapeShellArg group}";
  };
}
