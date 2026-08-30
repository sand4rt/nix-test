{ mkAction, ... }:
{
  /**
    @doc lib.test.step
    ## `lib.test.step`

    ```nix
    test.step "user sees ready state" [
      (expect.toBeVisible (terminal.getByText "ready"))
    ]
    ```

    Groups related actions under a diagnostic name.
  */
  step = name: actions: mkAction "step" {
    inherit name actions;
  };
}
