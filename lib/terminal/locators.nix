{
  /** @doc terminal.getByRegion
  ## `terminal.getByRegion`

  ```nix
  terminal.getByRegion {
    left = 0;
    top = 0;
    width = 80;
    height = 10;
  }
  ```

  Selects a rectangle of terminal cells for use with `expect(...).toEqual`.
  `left` and `top` default to `0`; `width` and `height` default to the remaining
  visible grid. Coordinates are zero-based.
  */
  getByRegion = options: {
    type = "region";
    left = options.left or 0;
    top = options.top or 0;
    width = options.width or null;
    height = options.height or null;
  };

  /** @doc terminal.getByText
  ## `terminal.getByText`

  ```nix
  terminal.getByText text
  ```

  Locates visible terminal text for use with `expect(...).toBeVisible`.
  Matching is literal and may span any visible part of the terminal grid.
  */
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
