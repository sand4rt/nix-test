{ expect, ... }:
{
  test."observes files exposed by the system" = { machine, filesystem }: [
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
    (expect (filesystem.file machine "/etc/nix-test/message")).toBeFile
    ((expect (filesystem.file machine "/etc/nix-test/message")).toHaveContent "hello from NixOS")
    (expect (filesystem.directory machine "/var/lib/nix-test")).toBeDirectory
    (expect (filesystem.symlink machine "/var/lib/nix-test/message")).toBeSymlink
    ((expect (filesystem.symlink machine "/var/lib/nix-test/message")).toPointTo "/etc/nix-test/message")
    ((expect (filesystem.directory machine "/var/lib/nix-test")).toHaveMode "0750")
  ];
}
