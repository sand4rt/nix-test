{
  lib,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.network
  ## `network`

  ```nix
  network.endpoint {
    from = machine;
    host = "server";
    port = 8080;
    transport = "tcp";
  }
  network.partition { left = [ server ]; right = [ client ]; }
  network.heal { left = [ server ]; right = [ client ]; }
  ```

  `host` defaults to `127.0.0.1` and `transport` defaults to `tcp`.
  Ports must be integers from 1 through 65535. Partition and heal execute once.
*/
let
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  endpointTarget = node: options:
    let normalized = if builtins.isInt options then { port = options; } else options;
    in
    assert builtins.elem (normalized.transport or "tcp") [ "tcp" "udp" ];
    assert builtins.isString (normalized.host or "127.0.0.1");
    assert builtins.isInt normalized.port && normalized.port > 0 && normalized.port <= 65535;
    mkLocator {
      type = "endpoint";
      inherit node;
      transport = normalized.transport or "tcp";
      host = normalized.host or "127.0.0.1";
      port = normalized.port;
      description = "${normalized.transport or "tcp"} endpoint ${normalized.host or "127.0.0.1"}:${toString normalized.port}";
    };
  partitionCode = operation: left: right:
    lib.concatMapStringsSep "\n" (source:
      lib.concatMapStringsSep "\n" (target:
        ''${nodeExpression source.name}.succeed("iptables ${operation} OUTPUT -d $(getent ahostsv4 ${target.name} | head -n1 | cut -d' ' -f1) -j DROP")''
      ) (if builtins.elem source left then right else left)
    ) (left ++ right);
in
{
  testing.fixtures.network = mkFixture (_fixtures: {
    /** Locate a TCP or UDP endpoint as observed from a machine. */
    endpoint = options: endpointTarget options.from.name (builtins.removeAttrs options [ "from" ]);
    /** Block traffic between two groups of machines. */
    partition = { left, right }: mkAction "networkPartition" {
      left = map (node: node.name) left;
      right = map (node: node.name) right;
      code = partitionCode "-I" left right;
    };
    /** Restore traffic between two groups of machines. */
    heal = { left, right }: mkAction "networkHeal" {
      left = map (node: node.name) left;
      right = map (node: node.name) right;
      code = partitionCode "-D" left right;
    };
  });
}
