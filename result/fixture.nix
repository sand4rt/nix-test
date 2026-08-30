{
  mkFixture,
  mkLocator,
  ...
}:
{
  testing.fixtures.result = mkFixture (_fixtures: {
    command = name: mkLocator {
      type = "commandResult";
      inherit name;
      description = "saved result ${name}";
    };
    stdout = name: mkLocator {
      type = "resultStdout";
      inherit name;
      description = "stdout from ${name}";
    };
    exitCode = name: mkLocator {
      type = "resultExitCode";
      inherit name;
      description = "exit code from ${name}";
    };
  });
}
