{
  getByRegion = options: {
    type = "region";
    left = options.left or 0;
    top = options.top or 0;
    width = options.width or null;
    height = options.height or null;
  };

  getByText = text: {
    type = "text";
    inherit text;
  };

  runtime = /* python */ ''
    def region(terminal, locator):
        lines = terminal.text().splitlines()
        selected = lines[locator["top"]:]
        selected = [line[locator["left"]:] for line in selected]
        if locator["height"] is not None:
            selected = selected[:locator["height"]]
        if locator["width"] is not None:
            selected = [line[:locator["width"]] for line in selected]
        return "\n".join(selected).rstrip()
  '';
}
