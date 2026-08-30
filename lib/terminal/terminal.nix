{
  actions = {
    open = command: {
      type = "open";
      inherit command;
    };
    press = keys: {
      type = "keys";
      inherit keys;
    };
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
