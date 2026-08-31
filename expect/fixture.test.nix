{ expect, ... }:
{
  test."matches visible terminal behavior" = { terminal }: [
    (terminal.open "printf 'signed in'")
    (expect (terminal.getByText "signed in")).toBeVisible
  ];
}
