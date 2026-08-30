{ test, ... }:
{
  test."groups a user journey into steps" = { terminal, expect }: [
    (terminal.open "printf 'welcome screen'")
    (test.step "user sees the welcome screen" [
      (expect.toBeVisible (terminal.getByText "welcome screen"))
    ])
  ];
}
