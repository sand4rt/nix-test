{
  lib,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
let
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  operation = target: command: mkAction "containerAction" {
    inherit (target) node;
    code = ''${nodeExpression target.node}.succeed(${builtins.toJSON command})'';
  };
in
{
  testing.fixtures.container = mkFixture (_fixtures: {
    locate = node: name: mkLocator {
      type = "container";
      inherit node name;
      description = "container ${name}";
    };
    start = target: operation target "nixos-container start ${lib.escapeShellArg target.name}";
    stop = target: operation target "nixos-container stop ${lib.escapeShellArg target.name}";
    restart = target: operation target "nixos-container restart ${lib.escapeShellArg target.name}";
    run = target: command:
      operation target "nixos-container run ${lib.escapeShellArg target.name} -- ${command}";
  });
}
