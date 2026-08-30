{
  /** @doc vm.configure
  ## `vm.configure`

  ```nix
  vm.configure {
    homeModules = [ module ];
  }
  ```

  Selects the NixOS VM backend and configures its Home Manager modules.
  `homeModules` defaults to an empty list. A test containing this action is run
  with `pkgs.testers.runNixOSTest` rather than the terminal runner.
  */
  configure = options: {
    type = "vmConfigure";
    homeModules = options.homeModules or [ ];
  };

  waitUntilSucceeds = command: ''machine.wait_until_succeeds(f"{user} " + ${builtins.toJSON command})'';

  fail = command: ''machine.fail(${builtins.toJSON command})'';
}
