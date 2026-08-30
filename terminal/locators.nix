{ mkLocator, ... }:
{
  testing.locators.terminal = {
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

  Selects a rectangle of terminal cells for use with `expect.toEqual`.
  `left` and `top` default to `0`; `width` and `height` default to the remaining
  visible grid. Coordinates are zero-based.
  */
  getByRegion = options: mkLocator {
    type = "terminalRegion";
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

  Locates visible terminal text for use with `expect.toBeVisible`.
  Matching is literal and may span any visible part of the terminal grid.
  */
    getByText = text: mkLocator {
      type = "terminalText";
      inherit text;
    };

  };
}
