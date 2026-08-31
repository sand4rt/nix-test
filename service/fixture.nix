{
  lib,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.service
  ## `service`

  ```nix
  (machine.service name).start
  (machine.service name).stop
  (machine.service name).restart
  (machine.service name).reload
  (machine.service name).logs
  ```

  Targets come from `machine.service`, `machine.userService`, or `user.service`.
  Lifecycle methods execute once; `logs` returns a matcher target.
*/
let
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  systemctl = target:
    if target.scope == "system" then
      "systemctl"
    else
      "systemctl --user -M ${lib.escapeShellArg "${target.user}@"}";
  operation = target: command: mkAction "serviceAction" {
    inherit (target) node;
    code = ''${nodeExpression target.node}.succeed(${builtins.toJSON command})'';
  };
in
{
  testing.fixtures.service = mkFixture (_fixtures: {
    /** Start a system or user service once. */
    start = target: operation target "${systemctl target} start ${lib.escapeShellArg target.name}";
    /** Stop a system or user service once. */
    stop = target: operation target "${systemctl target} stop ${lib.escapeShellArg target.name}";
    /** Restart a system or user service once. */
    restart = target: operation target "${systemctl target} restart ${lib.escapeShellArg target.name}";
    /** Reload a system or user service once. */
    reload = target: operation target "${systemctl target} reload ${lib.escapeShellArg target.name}";
    /** Locate journal output for a service. */
    logs = target: mkLocator {
      type = "serviceLogs";
      inherit (target) node scope;
      command =
        if target.scope == "system" then
          "journalctl --no-pager -o cat -u ${lib.escapeShellArg target.name}"
        else
          "journalctl --user -M ${lib.escapeShellArg "${target.user}@"} --no-pager -o cat -u ${lib.escapeShellArg target.name}";
      description = "logs for ${target.description}";
    };
  });
}
