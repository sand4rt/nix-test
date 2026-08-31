{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.filesystem
  ## `filesystem`

  ```nix
  filesystem.path machine path
  filesystem.file machine path
  filesystem.directory machine path
  filesystem.symlink machine path
  filesystem.mount machine path
  filesystem.jsonFile machine path
  filesystem.root
  filesystem.writeFile relativePath content
  filesystem.makeDirectory relativePath
  filesystem.copyFile source relativeDestination
  filesystem.copyTree source relativeDestination
  filesystem.symlinkFile target relativeLinkPath
  filesystem.setMode relativePath mode
  filesystem.remove relativePath
  ```

  Locator methods observe paths on a supplied machine. Mutation methods prepare
  files under an isolated runtime root shared by terminal and default-machine
  tests. Relative paths cannot be empty, absolute, `.`, or contain `..`.
*/
let
  root = "/tmp/nix-test";
  validPath = path:
    builtins.isString path
    && path != ""
    && path != "."
    && !(lib.hasPrefix "/" path)
    && builtins.all (part: part != "..") (lib.splitString "/" path);
  assertPath = path:
    assert lib.assertMsg (validPath path)
      "nix-test: filesystem fixture paths must be relative and cannot contain '..': ${path}";
    path;
  destination = path: "${root}/${assertPath path}";
  mutation = type: path: command: payload:
    mkAction type (payload // {
      path = assertPath path;
      code = "machine.succeed(${builtins.toJSON command})";
    });
  pathTarget = machine: path: kind: mkLocator {
    type = "path";
    node = machine.name;
    inherit kind;
    path = builtins.replaceStrings [ "$fixture" ] [ root ] path;
    description = "${kind} ${path}";
  };
in
{
  testing.fixtures.filesystem = mkFixture (_fixtures: {
    /** Isolated mutable root. Interpolate it into terminal or machine commands. */
    root = "$fixture";
    /** Write a file below the isolated root. */
    writeFile = path: content:
      let
        checked = assertPath path;
        source = pkgs.writeText (builtins.baseNameOf checked) content;
        target = destination checked;
      in
      mkAction "writeFile" {
        path = checked;
        inherit content;
        code = "machine.succeed(${
          builtins.toJSON (
            "mkdir -p ${lib.escapeShellArg (builtins.dirOf target)}"
            + " && cp ${source} ${lib.escapeShellArg target}"
          )
        })";
      };
    /** Create a directory below the isolated root. */
    makeDirectory = path:
      mutation "makeDirectory" path "mkdir -p ${lib.escapeShellArg (destination path)}" { };
    /** Copy one file below the isolated root. */
    copyFile = source: path:
      let
        target = destination path;
        sourcePath = toString (builtins.path {
          name = "nix-test-fixture-${builtins.baseNameOf (toString source)}";
          path = source;
        });
      in
      mutation "copyFile" path (
        "mkdir -p ${lib.escapeShellArg (builtins.dirOf target)}"
        + " && cp ${lib.escapeShellArg sourcePath} ${lib.escapeShellArg target}"
      ) { source = sourcePath; };
    /** Copy a directory tree below the isolated root. */
    copyTree = source: path:
      let
        target = destination path;
        sourcePath = toString (builtins.path {
          name = "nix-test-fixture-${builtins.baseNameOf (toString source)}";
          path = source;
        });
      in
      mutation "copyTree" path (
        "mkdir -p ${lib.escapeShellArg target}"
        + " && cp -R ${lib.escapeShellArg "${sourcePath}/."} ${lib.escapeShellArg target}"
      ) { source = sourcePath; };
    /** Create a symbolic link below the isolated root. */
    symlinkFile = target: path:
      let link = destination path;
      in mutation "symlink" path (
        "mkdir -p ${lib.escapeShellArg (builtins.dirOf link)}"
        + " && ln -sfn ${lib.escapeShellArg target} ${lib.escapeShellArg link}"
      ) { inherit target; };
    /** Change a path's mode below the isolated root. */
    setMode = path: mode:
      mutation "setMode" path (
        "chmod ${lib.escapeShellArg mode} ${lib.escapeShellArg (destination path)}"
      ) { inherit mode; };
    /** Remove a path below the isolated root. */
    remove = path:
      mutation "removePath" path "rm -rf ${lib.escapeShellArg (destination path)}" { };
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
