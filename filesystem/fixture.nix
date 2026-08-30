{
  mkFixture,
  mkLocator,
  ...
}:
let
  workspace = "/tmp/nix-test";
  pathTarget = node: path: kind: mkLocator {
    type = "path";
    inherit node kind;
    path = builtins.replaceStrings [ "$fixture" ] [ workspace ] path;
    description = "${kind} ${path}";
  };
in
{
  testing.fixtures.filesystem = mkFixture (_fixtures: {
    path = node: path: pathTarget node path "path";
    file = node: path: pathTarget node path "file";
    directory = node: path: pathTarget node path "directory";
    symlink = node: path: pathTarget node path "symlink";
    mount = node: path: pathTarget node path "mount";
    jsonFile = node: path: (pathTarget node path "json") // { type = "jsonFile"; };
  });
}
