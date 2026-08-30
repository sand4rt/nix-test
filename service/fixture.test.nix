{
  test."controls a service by name" = { machine, service, expect }: [
    (machine.configure {
      modules = [
        {
          systemd.services.greeter = {
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "echo 'greeting ready'";
          };
        }
      ];
    })
    (service.start (machine.service "greeter.service"))
    (expect.toBeActive (machine.service "greeter.service"))
    (expect.toHaveLog (machine.service "greeter.service") "greeting ready")
    (service.stop (machine.service "greeter.service"))
    (expect.toBeInactive (machine.service "greeter.service"))
  ];
}
