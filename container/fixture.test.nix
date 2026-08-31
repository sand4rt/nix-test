{ expect, ... }:
{
  test."controls a declarative container" =
    { machine }:
    let
      app = machine.container "app";
    in
    [
      (machine.configure {
        modules = [
          {
            containers.app = {
              autoStart = false;
              config = {
                system.stateVersion = "25.11";
              };
            };
          }
        ];
      })
      app.start
      (expect app).toBeRunning
      (app.run "touch /run/ready")
      app.stop
      (expect app).toBeStopped
    ];
}
