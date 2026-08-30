{ pkgs, ... }:
{
  test."prepares files a user can open" = { terminal, workspace, expect }: [
    (workspace.makeDirectory "notes")
    (workspace.writeFile "notes/welcome.txt" "workspace ready")
    (workspace.copyFile ./fixture.test.nix "notes/example.nix")
    (workspace.symlink "notes/welcome.txt" "current-note")
    (terminal.open "${pkgs.coreutils}/bin/cat current-note")
    (expect.toBeVisible (terminal.getByText "workspace ready"))
  ];
}
