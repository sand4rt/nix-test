{ pkgs, ... }:
{
  test."writes files at workspace root" =
    {
      terminal,
      workspace,
      expect,
    }:
    [
      (workspace.writeFile "message.txt" "root file ready\n")
      (terminal.open "${pkgs.coreutils}/bin/cat message.txt")
      (expect.toBeVisible (terminal.getByText "root file ready"))
    ];

  test."writes workspace files" =
    {
      terminal,
      workspace,
      expect,
    }:
    [
      (workspace.writeFile "nested/message.txt" "workspace ready\n")
      (terminal.open "${pkgs.coreutils}/bin/cat nested/message.txt")
      (expect.toBeVisible (terminal.getByText "workspace ready"))
    ];

  test."sends terminal input" = { terminal, expect }: [
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
    (expect.toBeVisible (terminal.getByText "received: hello"))
  ];

  test."matches terminal regions" = { terminal, expect }: [
    (terminal.open (
      pkgs.writeShellApplication {
        name = "print-region";
        text = "printf 'alpha\\nbeta\\n'";
      }
    ))
    (expect.toEqual {
      actual = terminal.getByRegion {
        width = 5;
        height = 2;
      };
      expected = ''
        alpha
        beta
      '';
    })
  ];

  test."applies terminal configuration" = { terminal, expect }: [
    (terminal.open (
      pkgs.writeShellApplication {
        name = "show-size";
        runtimeInputs = [ pkgs.coreutils ];
        text = "stty size";
      }
    ))
    (expect.toBeVisible (terminal.getByText "30 100"))
    terminal.print
  ];
}
