{ mkLocator, ... }:
{
  testing.locators.terminal = {
    /**
      @doc terminal-machine.getByRegion
      ## `getByRegion`

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

      Selects a rectangle of terminal cells for use with `(expect region).toEqual`. Trailing
      blank-cell whitespace is omitted from the selected text.
      `left` and `top` default to `0`; `width` and `height` default to the remaining
      visible grid. Coordinates are zero-based.
    */
    getByRegion =
      options:
      mkLocator {
        type = "terminalRegion";
        left = options.left or 0;
        top = options.top or 0;
        width = options.width or null;
        height = options.height or null;
      };

    /**
      @doc terminal-machine.getByText
      ## `getByText`

      <span class="backend-example" data-backend="terminal"></span>

      ```nix
      terminal.getByText text
      ```

      <span class="backend-example" data-backend="machine"></span>

      ```nix
      machine.getByText text
      ```

      Locates literal text in the visible terminal for use with
      `(expect text).toBeVisible` on either backend.
    */
    getByText =
      text:
      mkLocator {
        type = "terminalText";
        inherit text;
      };

  };
}
