{
  mkAction,
  mkMatcher,
  ...
}:
let
  makeExpectation = (import ./assertions.nix { inherit mkAction; }).make;
in
{
  /**
    @doc expect.terminal-machine
    ## `expect` (terminal and machine)

    These matchers receive locators created by either terminal interface
    implementation. They retry until they pass or the active backend times out.

    ### `toBeVisible`

    <span class="backend-example" data-backend="terminal"></span>

    ```nix
      (expect (terminal.getByText "ready")).toBeVisible
    ```

    <span class="backend-example" data-backend="machine"></span>

    ```nix
      (expect (machine.getByText "ready")).toBeVisible
    ```

    Passes when the locator's text appears in the visible terminal.

    ### `toEqual`

    <span class="backend-example" data-backend="terminal"></span>

    ```nix
      (expect (terminal.getByRegion region)).toEqual expected
    ```

    <span class="backend-example" data-backend="machine"></span>

    ```nix
      (expect (machine.getByRegion region)).toEqual expected
    ```

    Passes when the selected terminal text equals `expected`. Trailing blank-cell
    whitespace is ignored, as are the surrounding newlines in a Nix multiline
    string.
  */
  testing.matchers.toBeVisible = mkMatcher {
    accepts = [
      "machinePattern"
      "machineText"
      "terminalText"
      "browserElement"
      "desktopWindow"
      "desktopText"
    ];
    run =
      _fixtures: target:
      if target ? toBeVisible then target.toBeVisible else (makeExpectation target).toBeVisible;
  };

  testing.matchers.toEqual =
    fixtures: actual: expected:
    (mkMatcher {
      accepts = [
        "machineRegion"
        "terminalRegion"
      ];
      run =
        _fixtures: target:
        if target ? toEqual then target.toEqual expected else (makeExpectation target).toEqual expected;
    })
      fixtures
      actual;
}
