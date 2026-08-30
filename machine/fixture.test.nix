{ ... }:
{
  test."reports service state" = { machine, expect }: [
    (machine.configure {
      modules = [
        {
          systemd.services.example = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "touch /run/example-ready";
          };
        }
      ];
    })
    (expect.toEventuallySucceed (
      machine.command "systemctl is-active example.service"
    ))
    (machine.command "test -e /run/example-ready")
    (expect.toFail (machine.command "test -e /run/missing"))
  ];

  test."runs machine setup commands" = { machine }: [
    (machine.configure { modules = [ ]; })
    (machine.command "touch /run/setup-complete")
    (machine.command "test -e /run/setup-complete")
  ];

  test."drives a machine terminal" = { machine, expect }: [
    (machine.configure { modules = [ ]; })
    (machine.open "sh -c 'read value; printf \"received: %s\\n\" \"$value\"; sleep 30'")
    (machine.press "hello")
    (machine.press "<enter>")
    (expect.toBeVisible (machine.getByText "received: hello"))
    machine.print
  ];

  test."matches machine terminal regions" = { machine, expect }: [
    (machine.configure { modules = [ ]; })
    (machine.open "sh -c 'printf \"alpha\\nbeta\\n\"; sleep 30'")
    (expect.toEqual {
      actual = machine.getByRegion {
        width = 5;
        height = 2;
      };
      expected = ''
        alpha
        beta
      '';
    })
  ];
}
