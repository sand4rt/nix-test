{ pkgs, test, expect, ... }:
{
  test."terminal fixture" = { terminal, filesystem }: [
    (test.step "writes files at filesystem root" [
      (filesystem.writeFile "message.txt" "root file ready\n")
      (terminal.open "${pkgs.coreutils}/bin/cat message.txt")
      (expect (terminal.getByText "root file ready")).toBeVisible
    ])

    (test.step "writes filesystem files" [
      (filesystem.writeFile "nested/message.txt" "filesystem ready\n")
      (terminal.open "${pkgs.coreutils}/bin/cat nested/message.txt")
      (expect (terminal.getByText "filesystem ready")).toBeVisible
    ])

    (test.step "stages filesystem trees" [
      (filesystem.makeDirectory "nested")
      (filesystem.copyFile ./terminal.test.nix "nested/source.nix")
      (filesystem.symlinkFile "nested/source.nix" "source-link.nix")
      (filesystem.setMode "nested/source.nix" "0600")
      (filesystem.remove "source-link.nix")
      (terminal.open "${pkgs.coreutils}/bin/stat -c '%a %n' nested/source.nix")
      (expect (terminal.getByText "600 nested/source.nix")).toBeVisible
    ])

    (test.step "sends terminal input" [
      (terminal.open (
        pkgs.writeShellApplication {
          name = "echo-input";
          text = ''
            read -r value
            printf 'received: %s\n' "$value"
          '';
        }
      ))
      (terminal.press "hello<enter>")
      (expect (terminal.getByText "received: hello")).toBeVisible
    ])

    (test.step "matches terminal regions" [
      (terminal.open (
        pkgs.writeShellApplication {
          name = "print-region";
          text = "printf 'alpha\\nbeta\\n'";
        }
      ))
      ((expect (terminal.getByRegion {
        width = 5;
        height = 2;
      })).toEqual ''
        alpha
        beta
      '')
    ])

    (test.step "applies terminal configuration" [
      (terminal.open (
        pkgs.writeShellApplication {
          name = "show-size";
          runtimeInputs = [ pkgs.coreutils ];
          text = "stty size";
        }
      ))
      (expect (terminal.getByText "30 100")).toBeVisible
      terminal.print
    ])
  ];
}
