{ pkgs, expect, ... }:
{
  test."observes connectivity between machines" = { machines, network }:
  let
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
    (expect (server.service "example-server.service")).toBeActive
    (expect (network.endpoint {
      from = client;
      host = "server";
      port = 8080;
    })).toBeReachable
    (network.partition { left = [ client ]; right = [ server ]; })
    (expect (network.endpoint {
      from = client;
      host = "server";
      port = 8080;
    })).toBeUnreachable
    (network.heal { left = [ client ]; right = [ server ]; })
    (expect (network.endpoint {
      from = client;
      host = "server";
      port = 8080;
    })).toBeReachable
  ];
}
