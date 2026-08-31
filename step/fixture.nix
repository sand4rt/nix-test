{ mkAction, ... }:
{
  /**
    @doc test.step
    ### `test.step`

    Groups actions into a named step. The step appears as a nested subtest in
    the test log, making longer scenarios easier to read and debug.

    **Usage**

    ```nix
    test.step "service becomes usable" [
      (expect.toBeActive (machine.service "example.service"))
      (expect.toHaveStatus 200 (machine.http.get "http://localhost/health"))
    ]
    ```

    **Arguments**

    - `name`: Name shown in the test log.
    - `actions`: Ordered list of actions in the step.

    Returns an action that can be placed in a test's action list. Steps may
    contain other steps.
  */
  step = name: actions: mkAction "step" {
    inherit name actions;
  };
}
