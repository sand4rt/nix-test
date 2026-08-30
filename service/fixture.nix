{
  lib,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
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
    start = target: operation target "${systemctl target} start ${lib.escapeShellArg target.name}";
    stop = target: operation target "${systemctl target} stop ${lib.escapeShellArg target.name}";
    restart = target: operation target "${systemctl target} restart ${lib.escapeShellArg target.name}";
    reload = target: operation target "${systemctl target} reload ${lib.escapeShellArg target.name}";
    logs = target: mkLocator {
      type = "serviceLogs";
      inherit (target) node;
      command = "journalctl --no-pager -o cat -u ${lib.escapeShellArg target.name}";
      description = "logs for ${target.description}";
    };
  });
}
