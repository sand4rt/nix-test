{ test, ... }:
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
    (expect.toEventuallySucceed (machine.command "systemctl is-active example.service"))
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
    (machine.press "hello<enter>")
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

  test."uses the machine workspace" =
    {
      machine,
      workspace,
      expect,
    }:
    [
      (machine.configure { })
      (workspace.writeFile "message.txt" "workspace ready\n")
      (expect.toEventuallySucceed (machine.command "test -e ${workspace.path}/message.txt"))
      (machine.open "cat message.txt")
      (expect.toBeVisible (machine.getByText "workspace ready"))
    ];

  test."describes observable machine behavior" =
    {
      machine,
      service,
      workspace,
      expect,
    }:
    [
      (machine.configure {
        modules = [
          {
            systemd.services.observable = {
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script = "mkdir -p /run/observable && echo ready > /run/observable/state";
            };
          }
        ];
      })
      (test.step "observe public state" [
        (expect.toBeActive (machine.service "observable.service"))
        (expect.toExist (machine.file "/run/observable/state"))
        (expect.toHaveContent (machine.file "/run/observable/state") "ready")
      ])
      (service.restart (machine.service "observable.service"))
      (workspace.makeDirectory "nested")
      (workspace.writeFile "nested/message" "hello")
      (expect.toHaveContent (machine.file "${workspace.path}/nested/message") "hello")
    ];

  test."supports named machines" =
    { machines, expect }:
    let
      server = machines.node "server";
      client = machines.node "client";
    in
    [
      (machines.configure {
        server.modules = [ ];
        client.modules = [ ];
      })
      (server.command "echo ready > /run/server-ready")
      (expect.toExist (server.file "/run/server-ready"))
      (expect.toSucceed (client.command "true"))
    ];

  test."asserts saved command results" =
    { machine, result, expect }:
    [
      (machine.configure { })
      (machine.run {
        command = "printf ready";
        saveAs = "status";
      })
      (expect.toHaveExitCode 0 (result.command "status"))
      (expect.toHaveStdout (result.stdout "status") "ready")
    ];
}
