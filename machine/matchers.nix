{
  mkAction,
  mkMatcher,
  ...
}:
let
  makeExpectation = import ./assertions.nix { inherit mkAction; };
in
{
  /**
    @doc expect.machine-command
    ## `expect` (machine command)

    Machine matchers receive targets created by `machine.command`.

    ### `toEventuallySucceed`

    Retries the command until it succeeds or times out.

    ```nix
    expect.toEventuallySucceed (machine.command "test -e /run/example-ready")
    ```

    ### `toFail`

    Retries the command until it fails or the NixOS test driver times out.

    ```nix
    expect.toFail (machine.command "pgrep forbidden-process")
    ```
  */
  testing.matchers.toEventuallySucceed = mkMatcher {
    accepts = [ "machineCommand" ];
    run = _fixtures: target: (makeExpectation target).toEventuallySucceed;
  };

  testing.matchers.toFail = mkMatcher {
    accepts = [ "machineCommand" ];
    run = _fixtures: target: (makeExpectation target).toFail;
  };
}
