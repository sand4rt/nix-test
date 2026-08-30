{
  test."runs behavior as a configured user" = { machine, user, expect }: let
    operator = user.locate machine "operator";
  in [
    (machine.configure {
      modules = [
        {
          users.users.operator = {
            isNormalUser = true;
            extraGroups = [ "operators" ];
          };
          users.groups.operators = { };
        }
      ];
    })
    (expect.toExist operator)
    (expect.toBeMemberOf operator "operators")
    (user.run operator "echo ready > /tmp/operator-ready")
    (expect.toExist (machine.file "/tmp/operator-ready"))
    (expect.toBeOwnedBy (machine.file "/tmp/operator-ready") "operator")
  ];
}
