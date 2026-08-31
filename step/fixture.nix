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
      (expect (machine.service "example.service")).toBeActive
      ((expect (machine.http.get "http://localhost/health")).toHaveStatus 200)
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
