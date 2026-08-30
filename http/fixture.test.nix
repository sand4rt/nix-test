{ pkgs, ... }:
{
  test."observes an HTTP API" = { machine, http, result, expect }: [
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
    (expect.toHaveStatus 200 (machine.http.get "http://localhost:8080/status.json"))
    (expect.toHaveJsonValue {
      actual = http.getJson machine "http://localhost:8080/status.json";
      path = "status";
      expected = "ready";
    })
    (http.send machine {
      method = "GET";
      url = "http://localhost:8080/status.json";
      saveAs = "status";
    })
    (expect.toHaveExitCode 0 (result.command "status"))
    (expect.toContainStdout (result.stdout "status") "ready")
  ];
}
