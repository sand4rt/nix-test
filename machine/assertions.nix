{ mkAction }:
target:
assert target.type == "machineCommand";
let
  inherit (target) command;
  node = target.node or "machine";
  machine = ''machines[${builtins.toJSON node}]'';
in
{
  toEventuallySucceed = mkAction "machineAssertion" {
    inherit node;
    code = "${machine}.wait_until_succeeds(${builtins.toJSON command})";
  };

  toFail = mkAction "machineAssertion" {
    inherit node;
    code = "${machine}.wait_until_fails(${builtins.toJSON command})";
  };
}
