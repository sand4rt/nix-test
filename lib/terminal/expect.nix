{
  /** @doc expect.terminal
  ## `expect` (terminal)

  ```nix
  expect locator
  ```

  Creates retrying assertions for a terminal locator. Assertions retry until
  they pass or the test timeout expires, so tests should synchronize on
  observable output instead of using sleeps.

  ### `toBeVisible`

  ```nix
  ((expect (terminal.getByText "ready")).toBeVisible)
  ```

  Passes when the locator's text appears in the visible terminal.

  ### `toEqual`

  ```nix
  ((expect (terminal.getByRegion region)).toEqual expected)
  ```

  Passes when the selected terminal cells exactly equal `expected`, excluding
  surrounding newlines in the expected Nix multiline string.
  */
  make = target: {
    toBeVisible = {
      type = "assertText";
      text = target.text;
    };
    toEqual = expected: {
      type = "assertRegion";
      inherit expected;
      left = target.left;
      top = target.top;
      width = target.width;
      height = target.height;
    };
  };

  runtime = /* python */ ''
    import time

    from locators import region


    def assert_region(terminal, locator, timeout):
        expected = locator["expected"].strip("\n")
        deadline = time.monotonic() + timeout
        actual = ""
        while time.monotonic() < deadline:
            actual = region(terminal, locator)
            if actual == expected:
                return
            time.sleep(0.05)
        raise AssertionError(
            f"terminal region mismatch\nExpected:\n{expected}\nActual:\n{actual}\n\n"
            f"Full terminal:\n{terminal.text()}"
        )

    def assert_text(terminal, text, timeout):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if text in terminal.text():
                return
            time.sleep(0.05)
        raise AssertionError(f"text not visible: {text!r}\n{terminal.text()}")
  '';
}
