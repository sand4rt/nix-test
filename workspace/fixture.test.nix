{ pkgs, expect, ... }:
{
  test."prepares files a user can open" = { terminal, workspace }: [
    (workspace.makeDirectory "notes")
    (workspace.writeFile "notes/welcome.txt" "workspace ready")
    (workspace.copyFile ./fixture.test.nix "notes/example.nix")
    (workspace.symlink "notes/welcome.txt" "current-note")
    (terminal.open "${pkgs.coreutils}/bin/cat current-note")
    (expect (terminal.getByText "workspace ready")).toBeVisible
  ];
}
