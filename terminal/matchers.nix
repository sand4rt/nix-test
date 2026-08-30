{
  mkAction,
  mkMatcher,
  ...
}:
let
  makeExpectation = (import ./assertions.nix { inherit mkAction; }).make;
in
{
  /** @doc expect.terminal-machine
  ## `expect` (terminal and machine)

  Terminal matchers receive locators created by either backend fixture. They
  retry until they pass or the configured timeout expires.

  ### `toBeVisible`

  <span class="backend-example" data-backend="terminal"></span>

  ```nix
  expect.toBeVisible (terminal.getByText "ready")
  ```

  <span class="backend-example" data-backend="machine"></span>

  ```nix
  expect.toBeVisible (machine.getByText "ready")
  ```

  Passes when the locator's text appears in the visible terminal.

  ### `toEqual`

  <span class="backend-example" data-backend="terminal"></span>

  ```nix
  expect.toEqual {
    actual = terminal.getByRegion region;
    inherit expected;
  }
  ```

  <span class="backend-example" data-backend="machine"></span>

  ```nix
  expect.toEqual {
    actual = machine.getByRegion region;
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
