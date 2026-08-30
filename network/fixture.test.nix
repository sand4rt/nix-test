{ pkgs, ... }:
{
  test."observes connectivity between machines" = { machines, network, expect }: let
    server = machines.node "server";
    client = machines.node "client";
  in [
    (machines.configure {
      server.modules = [
        {
          networking.firewall.allowedTCPPorts = [ 8080 ];
          systemd.services.example-server = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.ExecStart = "${pkgs.python3}/bin/python -m http.server 8080";
          };
        }
      ];
      client.modules = [ ];
    })
    (expect.toBeReachable (network.endpoint {
      from = client;
      host = "server";
      port = 8080;
    }))
    (network.partition { left = [ client ]; right = [ server ]; })
    (expect.toBeUnreachable (network.endpoint {
      from = client;
      host = "server";
      port = 8080;
    }))
    (network.heal { left = [ client ]; right = [ server ]; })
    (expect.toBeReachable (network.endpoint {
      from = client;
      host = "server";
      port = 8080;
    }))
  ];
}
