{
  lib,
  mkAction,
  mkFixture,
  ...
}:
{
  testing.fixtures.terminal = (mkFixture (_fixtures: {
    /** @doc terminal.open
    ## `terminal.open`

    ```nix
    terminal.open commandOrPackage
    ```

    Starts a command in a real pseudo-terminal with the test workspace as its
    working directory. Pass a package to run its `meta.mainProgram`, or a string
    for commands with arguments. Only one terminal process is active per test.
    */
    open = command: mkAction "open" {
      command = if builtins.isString command then command else lib.getExe command;
    };

    /** @doc terminal.press
    ## `terminal.press`

    ```nix
    terminal.press keys
    ```

    Sends `keys` to the active terminal process. Text is sent literally except
    for `<leader>`, `<space>`, `<esc>`, `<escape>`, `<enter>`, `<cr>`, `<tab>`,
    and `<bs>`.
    */
    press = keys: mkAction "keys" { inherit keys; };

    /** @doc terminal.print
    ## `terminal.print`

    Prints the current terminal grid to the build log.
    */
    print = mkAction "print" { };
  })) // {
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
    '';
  };
}
