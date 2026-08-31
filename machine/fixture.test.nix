{ test, expect, ... }:
{
  test."reports service state" = { machine }: [
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
    (expect (machine.command "systemctl is-active example.service")).toEventuallySucceed
    (machine.command "test -e /run/example-ready")
    (expect (machine.command "test -e /run/missing")).toFail
  ];

  test."runs machine setup commands" = { machine }: [
    (machine.command "touch /run/setup-complete")
    (machine.command "test -e /run/setup-complete")
  ];

  test."drives a machine terminal" = { machine }: [
    (machine.open "sh -c 'read value; printf \"received: %s\\n\" \"$value\"; sleep 30'")
    (machine.press "hello<enter>")
    (expect (machine.getByText "received: hello")).toBeVisible
    machine.print
  ];

  test."matches machine terminal regions" = { machine }: [
    (machine.open "sh -c 'printf \"alpha\\nbeta\\n\"; sleep 30'")
    ((expect (machine.getByRegion {
        width = 5;
        height = 2;
      })).toEqual ''
        alpha
        beta
      '')
  ];

  test."uses the machine filesystem" = { machine, filesystem }: [
      (filesystem.writeFile "message.txt" "filesystem ready\n")
      (expect (machine.command "test -e ${filesystem.root}/message.txt")).toEventuallySucceed
      (machine.open "sh -c 'cat message.txt; sleep 30'")
      (expect (machine.getByText "filesystem ready")).toBeVisible
    ];

  test."describes observable machine behavior" = { machine, filesystem }: [
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
        (expect (machine.service "observable.service")).toBeActive
        (expect (machine.file "/run/observable/state")).toExist
        ((expect (machine.file "/run/observable/state")).toHaveContent "ready")
      ])
      (machine.service "observable.service").restart
      (filesystem.makeDirectory "nested")
      (filesystem.writeFile "nested/message" "hello")
      ((expect (machine.file "${filesystem.root}/nested/message")).toHaveContent "hello")
    ];

  test."supports named machines" = { machines }:
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
      (expect (server.file "/run/server-ready")).toExist
      (expect (client.command "true")).toSucceed
    ];

  test."asserts saved command results" = { machine, result }: [
      (machine.run {
        command = "printf ready";
        saveAs = "status";
      })
      ((expect (result.command "status")).toHaveExitCode 0)
      ((expect (result.stdout "status")).toHaveStdout "ready")
    ];
}
