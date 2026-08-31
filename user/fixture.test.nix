{ expect, ... }:
{
  test."runs behavior as a configured user" = { machine, user }:
  let
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
    (expect operator).toExist
    ((expect operator).toBeMemberOf "operators")
    (user.run operator "echo ready > /tmp/operator-ready")
    (expect (machine.file "/tmp/operator-ready")).toExist
    ((expect (machine.file "/tmp/operator-ready")).toBeOwnedBy "operator")
  ];
}
