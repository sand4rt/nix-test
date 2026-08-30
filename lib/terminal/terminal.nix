{
  actions = {
    /** @doc terminal.open
    ## `terminal.open`

    ```nix
    terminal.open command
    ```

    Starts `command` in a real pseudo-terminal with the test workspace as its
    working directory. Only one terminal process is active per test.

    Use `${workspace.path}` in the Nix string to refer to the isolated
    workspace. The command is split using shell-like quoting, but is executed
    directly rather than through a shell.
    */
    open = command: {
      type = "open";
      inherit command;
    };
    /** @doc terminal.press
    ## `terminal.press`

    ```nix
    terminal.press keys
    ```

    Sends `keys` to the active terminal process. Text is sent literally except
    for the supported key names: `<leader>`, `<space>`, `<esc>`, `<escape>`,
    `<enter>`, `<cr>`, `<tab>`, and `<bs>`.
    */
    press = keys: {
      type = "keys";
      inherit keys;
    };
    /** @doc terminal.print
    ## `terminal.print`

    ```nix
    terminal.print
    ```

    Prints the current terminal grid to the build log. This is a value, not a
    function, and is intended for debugging without adding an assertion.
    */
    print = {
      type = "print";
    };
  };

  runtime = /* python */ ''
    import shlex
    import shlex
    import time

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
}
