{ pkgs, expect, ... }:
{
  test."observes an HTTP API" = { machine, http, result }: [
    (machine.configure {
      modules = [
        {
          systemd.services.example-api = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.ExecStart = pkgs.writeShellScript "example-api" ''
              ${pkgs.python3}/bin/python -m http.server 8080 --directory ${pkgs.writeTextDir "status.json" ''{"status":"ready"}''}
            '';
          };
        }
      ];
    })
    ((expect (machine.http.get "http://localhost:8080/status.json")).toHaveStatus 200)
    ((expect (http.getJson machine "http://localhost:8080/status.json")).toHaveJsonValue {
      path = "status";
      value = "ready";
    })
    (http.send machine {
      method = "GET";
      url = "http://localhost:8080/status.json";
      saveAs = "status";
    })
    ((expect (result.command "status")).toHaveExitCode 0)
    ((expect (result.stdout "status")).toContainStdout "ready")
  ];
}
