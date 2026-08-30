{
  lib,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
let
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  endpointTarget = node: options:
    let normalized = if builtins.isInt options then { port = options; } else options;
    in mkLocator {
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
    endpoint = options: endpointTarget options.from.name (builtins.removeAttrs options [ "from" ]);
    partition = { left, right }: mkAction "networkPartition" {
      left = map (node: node.name) left;
      right = map (node: node.name) right;
      code = partitionCode "-I" left right;
    };
    heal = { left, right }: mkAction "networkHeal" {
      left = map (node: node.name) left;
      right = map (node: node.name) right;
      code = partitionCode "-D" left right;
    };
  });
}
