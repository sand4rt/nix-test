{
  lib,
  mkAction,
  mkFixture,
  ...
}:
{
  testing.fixtures.terminal =
    (mkFixture (_fixtures: {
      /**
        @doc terminal-machine.open
        ## `open`

        <span class="backend-example" data-backend="terminal"></span>

        ```nix
        terminal.open commandOrPackage
        ```

        <span class="backend-example" data-backend="machine"></span>

        ```nix
        machine.open commandOrPackage
        ```

    Starts a command in a persistent terminal with the test workspace as its
    working directory. Pass a package to run its `meta.mainProgram`, or a command
    string when arguments are needed. Only one terminal process is active per
    test.
      */
      open =
        command:
        mkAction "open" {
          command = if builtins.isString command then command else lib.getExe command;
        };

      /**
        @doc terminal-machine.press
        ## `press`

        <span class="backend-example" data-backend="terminal"></span>

        ```nix
        terminal.press keys
        ```

        <span class="backend-example" data-backend="machine"></span>

        ```nix
        machine.press keys
        ```

        Sends `keys` to the active terminal. Text is sent literally except
        for `<leader>`, `<space>`, `<esc>`, `<escape>`, `<enter>`, `<cr>`, `<c-w>`,
        `<tab>`, and `<bs>`.
      */
      press = keys: mkAction "keys" { inherit keys; };

      /**
        @doc terminal-machine.print
        ## `print`

        <span class="backend-example" data-backend="terminal"></span>

        ```nix
        terminal.print
        ```

        <span class="backend-example" data-backend="machine"></span>

        ```nix
        machine.print
        ```

        Prints the current terminal grid to the test log.
      */
      print = mkAction "print" { };
    }))
    // {
      runtime = /* python */ ''
        import shlex

        import pexpect
        import pyte


        KEYS = {
            "<leader>": " ",
            "<space>": " ",
            "<esc>": "\x1b",
            "<escape>": "\x1b",
            "<enter>": "\r",
            "<cr>": "\r",
            "<tab>": "\t",
            "<bs>": "\x7f",
        }


        def parse_keys(keys):
            for notation, value in KEYS.items():
                keys = keys.replace(notation, value)
            return keys


        class Terminal:
            def __init__(self, columns, rows):
                self.screen = pyte.Screen(columns, rows)
                self.screen.report_device_status = lambda mode, **_: None
                self.stream = pyte.Stream(self.screen)
                self.child = None

            def text(self):
                self.pump()
                return "\n".join(line.rstrip() for line in self.screen.display)

            def pump(self):
                if self.child is None:
                    return
                while True:
                    try:
                        output = self.child.read_nonblocking(65536, 0)
                    except (pexpect.TIMEOUT, pexpect.exceptions.EOF):
                        return
                    self.stream.feed(output.decode("utf-8", "replace"))

            def open(self, command, fixture, rows, columns):
                self.close()
                args = [arg.replace("$fixture", fixture) for arg in shlex.split(command)]
                self.child = pexpect.spawn(
                    args[0], args[1:], cwd=fixture,
                    dimensions=(rows, columns), encoding=None, timeout=1,
                )

            def press(self, keys):
                self.child.send(parse_keys(keys))
                self.pump()

            def close(self):
                if self.child is not None and self.child.isalive():
                    self.child.send("q")
                if self.child is not None:
                    self.child.close(force=True)
                    self.child = None
      '';
    };
}
