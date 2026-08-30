{ pkgs, ... }:
{
  test."sends a chat message" = { machine, expect }: [
    (machine.configure {
      modules = [
        {
          services.ngircd = {
            enable = true;
            config = ''
              [Global]
              Name = irc.example.test
              Info = Nix Test IRC
              AdminInfo1 = Nix Test
              AdminInfo2 = Local test server
              AdminEMail = admin@example.test
              Listen = 127.0.0.1
              MotdPhrase = Welcome to Nix Test IRC
              Ports = 6667

              [Options]
              PAM = no

              [Channel]
              Name = #nix-test
            '';
          };
          environment.systemPackages = [ pkgs.irssi ];
        }
      ];
    })
    (expect.toBeActive (machine.service "ngircd.service"))
    (machine.open "irssi --connect localhost --nick alice")
    (expect.toBeVisible (machine.getByText "Welcome to Nix Test IRC"))
    (machine.press "/join #nix-test<enter>")
    (expect.toBeVisible (machine.getByText "#nix-test"))
    (machine.press "Hello from Nix!<enter>")
    (expect.toBeVisible (machine.getByText "Hello from Nix!"))
  ];
}
