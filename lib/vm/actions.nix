{
  configure = options: {
    type = "vmConfigure";
    homeModules = options.homeModules or [ ];
  };

  waitUntilSucceeds = command: ''machine.wait_until_succeeds(f"{user} " + ${builtins.toJSON command})'';

  fail = command: ''machine.fail(${builtins.toJSON command})'';
}
