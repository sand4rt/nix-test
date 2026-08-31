{ expect, ... }:
{
  test."asserts a saved user-visible result" = { machine, result }: [
    (machine.configure { })
    (machine.run {
      command = "printf 'account created'";
      saveAs = "create-account";
    })
    ((expect (result.command "create-account")).toHaveExitCode 0)
    ((expect (result.stdout "create-account")).toHaveStdout "account created")
    ((expect (result.stdout "create-account")).toContainStdout "created")
  ];
}
