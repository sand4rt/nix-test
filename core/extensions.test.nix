{ inputs, ... }:
{
  perSystem = { expect, ... }: {
    testing.fixtures.app = inputs.self.lib.mkFixture (
      { machine, ... }:
      {
        status = name:
          inputs.self.lib.mkLocator {
            type = "appStatus";
            node = machine.name;
            service = "${name}.service";
            description = "application ${name}";
          };
      }
    );

    testing.matchers.toBeOperational = inputs.self.lib.mkMatcher {
      accepts = [ "appStatus" ];
      run = { machine, expect, ... }: target:
        (expect (machine.service target.service)).toBeActive;
    };

    test."custom fixtures and matchers" = { app, machine }: [
      (machine.configure {
        modules = [
          {
            systemd.services.api = {
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script = "touch /run/api-ready";
            };
          }
        ];
      })
      (expect (app.status "api")).toBeOperational
    ];
  };
}
