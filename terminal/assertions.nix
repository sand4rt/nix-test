{ mkAction }:
{
  make = target: {
    toBeVisible = mkAction "assertText" {
      text = target.text;
    };
    toEqual = expected: mkAction "assertRegion" {
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
