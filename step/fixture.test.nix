{ ... }:
{
  test."groups a user journey into steps" = { terminal, step, expect }: [
    (terminal.open "printf 'welcome screen'")
    (step "user sees the welcome screen" [
      (expect.toBeVisible (terminal.getByText "welcome screen"))
    ])
  ];
}
