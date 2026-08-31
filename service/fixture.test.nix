{ expect, ... }:
{
  test."controls a service by name" = { machine }: [
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
    (machine.service "greeter.service").start
    (expect (machine.service "greeter.service")).toBeActive
    ((expect (machine.service "greeter.service").logs).toContain "greeting ready")
    (machine.service "greeter.service").stop
    (expect (machine.service "greeter.service")).toBeInactive
  ];
}
