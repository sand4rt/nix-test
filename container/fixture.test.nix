{
  test."controls a declarative container" = { machine, container, expect }: let
    app = container.locate machine "app";
  in [
    (machine.configure {
      modules = [
        {
          containers.app = {
            autoStart = false;
            config = { ... }: {
              system.stateVersion = "25.11";
            };
          };
        }
      ];
    })
    (container.start app)
    (expect.toBeRunning app)
    (container.run app "touch /run/ready")
    (container.stop app)
    (expect.toBeStopped app)
  ];
}
