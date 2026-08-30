{
  test."matches visible terminal behavior" = { terminal, expect }: [
    (terminal.open "printf 'signed in'")
    (expect.toBeVisible (terminal.getByText "signed in"))
  ];
}
