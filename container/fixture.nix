{
  lib,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.container
  ## `container`

  ```nix
  container.locate machine name
  (machine.container name).start
  (machine.container name).stop
  (machine.container name).restart
  (machine.container name).run command
  ```

  `locate` returns a declarative NixOS container locator. The remaining methods
  create one-shot actions for that container.
*/
let
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  operation = target: command: mkAction "containerAction" {
    inherit (target) node;
    code = ''${nodeExpression target.node}.succeed(${builtins.toJSON command})'';
  };
in
{
  testing.fixtures.container = mkFixture (_fixtures: {
    /** Locate a declarative NixOS container. */
    locate = machine: name: mkLocator {
      type = "container";
      node = machine.name;
      inherit name;
      description = "container ${name}";
    };
    /** Start a container once. */
    start = target: operation target "nixos-container start ${lib.escapeShellArg target.name}";
    /** Stop a container once. */
    stop = target: operation target "nixos-container stop ${lib.escapeShellArg target.name}";
    /** Restart a container once. */
    restart = target: operation target "nixos-container restart ${lib.escapeShellArg target.name}";
    /** Run a public command once inside a container. */
    run = target: command:
      operation target "nixos-container run ${lib.escapeShellArg target.name} -- ${command}";
  });
}
