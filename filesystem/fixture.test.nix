{ ... }:
{
  test."observes files exposed by the system" = { machine, filesystem, expect }: [
    (machine.configure {
      modules = [
        {
          environment.etc."nix-test/message".text = "hello from NixOS";
          systemd.tmpfiles.rules = [
            "d /var/lib/nix-test 0750 root root -"
            "L+ /var/lib/nix-test/message - - - - /etc/nix-test/message"
          ];
        }
      ];
    })
    (expect.toBeFile (filesystem.file machine "/etc/nix-test/message"))
    (expect.toHaveContent (filesystem.file machine "/etc/nix-test/message") "hello from NixOS")
    (expect.toBeDirectory (filesystem.directory machine "/var/lib/nix-test"))
    (expect.toBeSymlink (filesystem.symlink machine "/var/lib/nix-test/message"))
    (expect.toPointTo (filesystem.symlink machine "/var/lib/nix-test/message") "/etc/nix-test/message")
    (expect.toHaveMode (filesystem.directory machine "/var/lib/nix-test") "0750")
  ];
}
