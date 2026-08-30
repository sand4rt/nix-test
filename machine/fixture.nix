{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  ...
}:
let
  session = "nix-testing";
  tmux = lib.getExe pkgs.tmux;
  workspace = "/tmp/nix-testing";
  resolveWorkspace = builtins.replaceStrings [ "$fixture" ] [ workspace ];
  commandAction =
    command:
    mkAction "machineAssertion" {
      code = "machine.succeed(${builtins.toJSON (resolveWorkspace command)})";
    };
  keyNames = {
    "<bs>" = "BSpace";
    "<cr>" = "Enter";
    "<c-w>" = "C-w";
    "<enter>" = "Enter";
    "<esc>" = "Escape";
    "<escape>" = "Escape";
    "<leader>" = "Space";
    "<space>" = "Space";
    "<tab>" = "Tab";
  };
  sendKeys =
    keys:
    lib.concatStringsSep " && " (
      builtins.map
        (
          part:
          if builtins.isList part then
            "${tmux} send-keys -t ${session} ${keyNames.${builtins.head part}}"
          else
            "${tmux} send-keys -t ${session} -l -- ${lib.escapeShellArg part}"
        )
        (
          builtins.filter (part: part != "") (
            builtins.split "(<bs>|<cr>|<c-w>|<enter>|<esc>|<escape>|<leader>|<space>|<tab>)" keys
          )
        )
    );
in
{
  testing.fixtures.machine = mkFixture (_fixtures: {
    /**
      @doc machine.configure
      ## `machine.configure`

      ```nix
      machine.configure {
        modules = [ module ];
      }
      ```

      Selects the NixOS machine backend and configures its NixOS modules. `modules`
      defaults to an empty list.
    */
    configure =
      options:
      mkAction "machineConfigure" {
        modules = [
          { environment.systemPackages = [ pkgs.tmux ]; }
        ]
        ++ (options.modules or [ ]);
      };

    /**
      @doc machine.command
      ## `machine.command`

      ```nix
      machine.command "mkdir -p /root/project"
      ```

      Runs a command once on the NixOS machine, prints its standard output, and
      fails the test on a non-zero exit status. The returned action can also be
      passed to `toEventuallySucceed` or `toFail` when different semantics are
      required.
    */
    command =
      command:
      mkAction "machineCommand" {
        inherit command;
        code = ''print(machine.succeed(${builtins.toJSON (resolveWorkspace command)}), end="")'';
      };

    open =
      command:
      let
        executable = resolveWorkspace (if builtins.isString command then command else lib.getExe command);
      in
      commandAction (
        "${tmux} new-session -d -x 140 -y 50 -s ${session} " + lib.escapeShellArg executable
      );

    press = keys: commandAction (sendKeys keys);

    print = mkAction "machineAssertion" {
      code = "print(machine.succeed(${builtins.toJSON "${tmux} capture-pane -p -t ${session}"}))";
    };
  });
}
