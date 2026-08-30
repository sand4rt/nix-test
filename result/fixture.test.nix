{
  test."asserts a saved user-visible result" = { machine, result, expect }: [
    (machine.configure { })
    (machine.run {
      command = "printf 'account created'";
      saveAs = "create-account";
    })
    (expect.toHaveExitCode 0 (result.command "create-account"))
    (expect.toHaveStdout (result.stdout "create-account") "account created")
    (expect.toContainStdout (result.stdout "create-account") "created")
  ];
}
