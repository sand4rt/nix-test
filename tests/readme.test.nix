{ lib, pkgs, expect, ... }:
{
  test."sends a chat message" = { machine }: [
    (machine.configure {
      modules = [
        {
          services.ngircd = {
            enable = true;
            config = lib.generators.toINI { } {
              Global = {
                Name = "irc.example.test";
                Info = "Nix Test IRC";
                AdminInfo1 = "Nix Test";
                AdminInfo2 = "Local test server";
                AdminEMail = "admin@example.test";
                Listen = "127.0.0.1";
                MotdPhrase = "Welcome to Nix Test IRC";
                Ports = 6667;
              };
              Options.PAM = false;
              Channel.Name = "#nix-test";
            };
          };
          environment.systemPackages = [ pkgs.irssi ];
        }
      ];
    })
    (expect (machine.service "ngircd.service")).toBeActive
    (machine.open "irssi --connect localhost --nick alice")
    (expect (machine.getByText "Welcome to Nix Test IRC")).toBeVisible
    (machine.press "/join #nix-test<enter>")
    (expect (machine.getByText "#nix-test")).toBeVisible
    (machine.press "Hello from Nix!<enter>")
    (expect (machine.getByText "Hello from Nix!")).toBeVisible
  ];
}
