{ mkLocator, ... }:
{
  testing.locators.terminal = {
  /** @doc terminal-machine.getByRegion
  ## `terminal.getByRegion` / `machine.getByRegion`

  <span class="backend-example" data-backend="terminal"></span>

  ```nix
  terminal.getByRegion {
    left = 0;
    top = 0;
    width = 80;
    height = 10;
  }
  ```

  <span class="backend-example" data-backend="machine"></span>

  ```nix
  machine.getByRegion {
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

  /** @doc terminal-machine.getByText
  ## `terminal.getByText` / `machine.getByText`

  <span class="backend-example" data-backend="terminal"></span>

  ```nix
  terminal.getByText text
  ```

  <span class="backend-example" data-backend="machine"></span>

  ```nix
  machine.getByText text
  ```

  Locates visible terminal text for use with `expect.toBeVisible` on either
  backend.
  Matching is literal and may span any visible part of the terminal grid.
  */
    getByText = text: mkLocator {
      type = "terminalText";
      inherit text;
    };

  };
}
