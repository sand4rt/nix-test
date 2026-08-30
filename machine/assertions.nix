{ mkAction }:
target:
assert target.type == "machineCommand";
let
  inherit (target) command;
in
{
  toEventuallySucceed = mkAction "machineAssertion" {
    code = ''machine.wait_until_succeeds(${builtins.toJSON command})'';
  };

  toFail = mkAction "machineAssertion" {
    code = ''machine.fail(${builtins.toJSON command})'';
  };
}
