{
  lib,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.user
  ## `user`

  ```nix
  user.locate machine name
  user.run target command
  user.service target serviceName
  ```

  `locate` returns a user locator. `run` executes a command once as that user,
  while `service` returns a user-level service locator.
*/
let
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
in
{
  testing.fixtures.user = mkFixture (_fixtures: {
    locate = machine: name: mkLocator {
      type = "user";
      node = machine.name;
      inherit name;
      description = "user ${name}";
    };
    run = target: command: mkAction "userCommand" {
      inherit (target) node;
      code = ''${nodeExpression target.node}.succeed(${builtins.toJSON (
        "runuser -u ${lib.escapeShellArg target.name} -- sh -lc ${lib.escapeShellArg command}"
      )})'';
    };
    service = target: name: mkLocator {
      type = "service";
      inherit (target) node;
      inherit name;
      scope = "user";
      user = target.name;
      description = "user service ${name}";
    };
  });
}
