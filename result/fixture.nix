{
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.result
  ## `result`

  ```nix
  result.command name
  result.stdout name
  result.exitCode name
  ```

  These methods locate results saved by `machine.run` or `http.send`. Assertions
  inspect the saved value without repeating the original side effect.
*/
{
  testing.fixtures.result = mkFixture (_fixtures: {
    /** Locate a complete saved command or request result. */
    command = name: mkLocator {
      type = "commandResult";
      inherit name;
      description = "saved result ${name}";
    };
    /** Locate stdout from a saved result. */
    stdout = name: mkLocator {
      type = "resultStdout";
      inherit name;
      description = "stdout from ${name}";
    };
    /** Locate the exit code from a saved result. */
    exitCode = name: mkLocator {
      type = "resultExitCode";
      inherit name;
      description = "exit code from ${name}";
    };
  });
}
