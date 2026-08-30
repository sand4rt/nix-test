command: {
  toSucceed = {
      type = "vmCommand";
    code = ''machine.succeed(f"{user} " + ${builtins.toJSON command})'';
  };

  toEventuallySucceed = {
      type = "vmCommand";
    code = ''machine.wait_until_succeeds(f"{user} " + ${builtins.toJSON command})'';
  };

  toFail = {
      type = "vmCommand";
    code = ''machine.fail(${builtins.toJSON command})'';
  };
}
