{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  ...
}:
let
  validPath =
    path:
    builtins.isString path
    && !(lib.hasPrefix "/" path)
    && builtins.all (part: part != "..") (lib.splitString "/" path);
  assertPath =
    path:
    assert lib.assertMsg (validPath path)
      "nix-test: workspace paths must be relative and cannot contain '..': ${path}";
    path;
  destination = path: "/tmp/nix-test/${assertPath path}";
  machineAction =
    type: path: command: payload:
    mkAction type (
      payload
      // {
        path = assertPath path;
        code = "machine.succeed(${builtins.toJSON command})";
      }
    );
in
{
  testing.fixtures.workspace = mkFixture (_fixtures: {
    /**
      @doc workspace.path
      ## `workspace.path`

      ```nix
      workspace.path
      ```

      Placeholder for the test's isolated workspace path. Interpolate it into a
      terminal or machine command; the selected backend replaces it with the
      actual writable path.
    */
    path = "$fixture";

    /**
      @doc workspace.writeFile
      ## `workspace.writeFile`

      ```nix
      workspace.writeFile path content
      ```

      Writes `content` to a path relative to the isolated workspace, creating
      parent directories as needed.
    */
    writeFile =
      path: content:
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

    makeDirectory =
      path:
      let
        target = destination path;
      in
      machineAction "makeDirectory" path "mkdir -p ${lib.escapeShellArg target}" { };

    copyFile =
      source: path:
      let
        target = destination path;
        sourcePath = toString (builtins.path {
          path = source;
          name = "nix-test-fixture-${builtins.baseNameOf (toString source)}";
        });
      in
      machineAction "copyFile" path (
        "mkdir -p ${lib.escapeShellArg (builtins.dirOf target)}"
        + " && cp ${lib.escapeShellArg sourcePath} ${lib.escapeShellArg target}"
      ) { source = sourcePath; };

    copyTree =
      source: path:
      let
        target = destination path;
        sourcePath = toString (builtins.path {
          path = source;
          name = "nix-test-fixture-${builtins.baseNameOf (toString source)}";
        });
      in
      machineAction "copyTree" path (
        "mkdir -p ${lib.escapeShellArg target}"
        + " && cp -R ${lib.escapeShellArg "${sourcePath}/."} ${lib.escapeShellArg target}"
      ) { source = sourcePath; };

    symlink =
      target: path:
      let
        link = destination path;
      in
      machineAction "symlink" path (
        "mkdir -p ${lib.escapeShellArg (builtins.dirOf link)}"
        + " && ln -sfn ${lib.escapeShellArg target} ${lib.escapeShellArg link}"
      ) { inherit target; };

    setMode =
      path: mode:
      machineAction "setMode" path (
        "chmod ${lib.escapeShellArg mode} ${lib.escapeShellArg (destination path)}"
      ) { inherit mode; };

    remove =
      path: machineAction "removePath" path "rm -rf ${lib.escapeShellArg (destination path)}" { };
  });
}
