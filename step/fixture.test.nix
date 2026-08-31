{ test, expect, ... }:
{
  test."groups a user journey into steps" = { terminal }: [
    (terminal.open "printf 'welcome screen'")
    (test.step "user sees the welcome screen" [
      (expect (terminal.getByText "welcome screen")).toBeVisible
    ])
  ];
}
