{ pkgs, expect, ... }:
{
  test."writes files at filesystem root" = { terminal, filesystem }: [
      (filesystem.writeFile "message.txt" "root file ready\n")
      (terminal.open "${pkgs.coreutils}/bin/cat message.txt")
      (expect (terminal.getByText "root file ready")).toBeVisible
    ];

  test."writes filesystem files" = { terminal, filesystem }: [
      (filesystem.writeFile "nested/message.txt" "filesystem ready\n")
      (terminal.open "${pkgs.coreutils}/bin/cat nested/message.txt")
      (expect (terminal.getByText "filesystem ready")).toBeVisible
    ];

  test."stages filesystem trees" = { terminal, filesystem }: [
      (filesystem.makeDirectory "nested")
      (filesystem.copyFile ./terminal.test.nix "nested/source.nix")
      (filesystem.symlinkFile "nested/source.nix" "source-link.nix")
      (filesystem.setMode "nested/source.nix" "0600")
      (filesystem.remove "source-link.nix")
      (terminal.open "${pkgs.coreutils}/bin/stat -c '%a %n' nested/source.nix")
      (expect (terminal.getByText "600 nested/source.nix")).toBeVisible
    ];

  test."sends terminal input" = { terminal }: [
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
  ];

  test."matches terminal regions" = { terminal }: [
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
  ];

  test."applies terminal configuration" = { terminal }: [
    (terminal.open (
      pkgs.writeShellApplication {
        name = "show-size";
        runtimeInputs = [ pkgs.coreutils ];
        text = "stty size";
      }
    ))
    (expect (terminal.getByText "30 100")).toBeVisible
    terminal.print
  ];
}
