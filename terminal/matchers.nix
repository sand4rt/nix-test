{
  mkAction,
  mkMatcher,
  ...
}:
let
  makeExpectation = (import ./assertions.nix { inherit mkAction; }).make;
in
{
  /** @doc expect.terminal
  ## `expect` (terminal)

  Terminal matchers receive locators created by the `terminal` fixture. They
  retry until they pass or the configured timeout expires.

  ### `toBeVisible`

  ```nix
  expect.toBeVisible (terminal.getByText "ready")
  ```

  Passes when the locator's text appears in the visible terminal.

  ### `toEqual`

  ```nix
  expect.toEqual {
    actual = terminal.getByRegion region;
    inherit expected;
  }
  ```

  Passes when the selected terminal cells exactly equal `expected`, excluding
  surrounding newlines in the expected Nix multiline string.
  */
  testing.matchers.toBeVisible = mkMatcher {
    accepts = [
      "machinePattern"
      "machineText"
      "terminalText"
    ];
    run = _fixtures: target:
      if target ? toBeVisible then
        target.toBeVisible
      else
        (makeExpectation target).toBeVisible;
  };

  testing.matchers.toEqual = fixtures: { actual, expected }:
    (mkMatcher {
      accepts = [
        "machineRegion"
        "terminalRegion"
      ];
      run = _fixtures: target:
        if target ? toEqual then
          target.toEqual expected
        else
          (makeExpectation target).toEqual expected;
    }) fixtures actual;
}
