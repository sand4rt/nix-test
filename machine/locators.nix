{
  lib,
  mkAction,
  mkLocator,
  ...
}:
let
  capture = "tmux capture-pane -p -t nix-testing";
  visible = command: mkAction "machineAssertion" {
    code = ''machine.wait_until_succeeds(${builtins.toJSON command})'';
  };
in
{
  testing.locators.machine = {
    /** @doc machine.getByText
    ## `machine.getByText`

    Locates literal text in the visible machine terminal.
    */
    getByText = text: mkLocator {
      type = "machineText";
      inherit text;
      toBeVisible = visible (
        "${capture} | grep -F -- ${lib.escapeShellArg text}"
      );
    };

    /** @doc machine.getByPattern
    ## `machine.getByPattern`

    Locates a regular expression in the visible machine terminal.
    */
    getByPattern = pattern: mkLocator {
      type = "machinePattern";
      inherit pattern;
      toBeVisible = visible (
        "${capture} | grep -E -- ${lib.escapeShellArg pattern}"
      );
    };

    /** @doc machine.getByRegion
    ## `machine.getByRegion`

    ```nix
    machine.getByRegion {
      left = 0;
      top = 0;
      width = 80;
      height = 10;
    }
    ```

    Selects a rectangular ASCII region from the visible machine terminal for
    use with `expect.toEqual`.
    */
    getByRegion = options: mkLocator {
      type = "machineRegion";
      left = options.left or 0;
      top = options.top or 0;
      width = options.width or null;
      height = options.height or null;
      toEqual = expected:
        let
          top = options.top or 0;
          left = options.left or 0;
          height = options.height or null;
          width = options.width or null;
          select = lib.concatStringsSep " | " (
            [ capture ]
            ++ lib.optional (top > 0) "tail -n +${toString (top + 1)}"
            ++ lib.optional (height != null) "head -n ${toString height}"
            ++ lib.optional (left > 0) "cut -c ${toString (left + 1)}-"
            ++ lib.optional (width != null) "cut -c 1-${toString width}"
            ++ [ "sed 's/[[:space:]]*$//'" ]
          );
          normalized = lib.removeSuffix "\n" (lib.removePrefix "\n" expected);
          command = "test \"$(${select})\" = ${lib.escapeShellArg normalized}";
        in
        mkAction "machineAssertion" {
          code = ''machine.wait_until_succeeds(${builtins.toJSON command})'';
        };
    };
  };
}
