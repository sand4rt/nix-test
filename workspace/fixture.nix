{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  ...
}:
{
  testing.fixtures.workspace = mkFixture (_fixtures: {
    /** @doc workspace.path
    ## `workspace.path`

    ```nix
    workspace.path
    ```

    Placeholder for the test's isolated workspace path. Interpolate it into a
    terminal or machine command; the selected backend replaces it with the
    actual writable path.
    */
    path = "$fixture";

    /** @doc workspace.writeFile
    ## `workspace.writeFile`

    ```nix
    workspace.writeFile path content
    ```

    Writes `content` to a path relative to the isolated workspace, creating
    parent directories as needed.
    */
    writeFile = path: content:
      let
        source = pkgs.writeText (builtins.baseNameOf path) content;
        destination = "/tmp/nix-testing/${path}";
      in
      mkAction "writeFile" {
        inherit path content;
        code = ''machine.succeed(${builtins.toJSON (
          "mkdir -p ${lib.escapeShellArg (builtins.dirOf destination)}"
          + " && cp ${source} ${lib.escapeShellArg destination}"
        )})'';
      };
  });
}
