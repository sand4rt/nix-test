{
  mkFixture,
  mkLocator,
  ...
}:
let
  workspace = "/tmp/nix-test";
  pathTarget = machine: path: kind: mkLocator {
    type = "path";
    node = machine.name;
    inherit kind;
    path = builtins.replaceStrings [ "$fixture" ] [ workspace ] path;
    description = "${kind} ${path}";
  };
in
{
  testing.fixtures.filesystem = mkFixture (_fixtures: {
    /** Locate any path on a machine. */
    path = node: path: pathTarget node path "path";
    /** Locate a regular file on a machine. */
    file = node: path: pathTarget node path "file";
    /** Locate a directory on a machine. */
    directory = node: path: pathTarget node path "directory";
    /** Locate a symbolic link on a machine. */
    symlink = node: path: pathTarget node path "symlink";
    /** Locate a mount point on a machine. */
    mount = node: path: pathTarget node path "mount";
    /** Locate a JSON document on a machine. */
    jsonFile = node: path: (pathTarget node path "json") // { type = "jsonFile"; };
  });
}
