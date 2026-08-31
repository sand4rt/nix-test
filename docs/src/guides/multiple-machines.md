# Multiple Machines

Use `machines` when a scenario crosses machine boundaries.

```nix
test."client reaches server" = { machines, network, expect }: let
  server = machines.node "server";
  client = machines.node "client";
in [
  (machines.configure {
    server.modules = [ serverModule ];
    client.modules = [ clientModule ];
  })

  (expect.toBeActive (server.service "example.service"))
  (expect.toSucceed (client.command "example-client server"))
]
```

Each node exposes the machine, terminal, service, filesystem, endpoint, HTTP,
user, and container APIs. Nodes also provide lifecycle actions such as `start`,
`shutdown`, `reboot`, and `crash`.

## Network Partitions

Use the network fixture to model failures explicitly:

```nix
[
  (network.partition { left = [ server ]; right = [ client ]; })
  (expect.toBeUnreachable (network.endpoint {
    from = client;
    host = "server";
    port = 8080;
  }))
  (network.heal { left = [ server ]; right = [ client ]; })
]
```

Use unique host ports when forwarding ports from more than one VM. See
[Port forwarding](../debugging.md#forward-a-service-port).
