{
  actions = {
    /** @doc workspace.path
    ## `workspace.path`

    ```nix
    workspace.path
    ```

    Placeholder for the test's isolated workspace path. Interpolate it into a
    command passed to `terminal.open`; the runtime replaces it with the actual
    temporary path.
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
    writeFile = path: content: {
      type = "writeFile";
      inherit path content;
    };
    /** @doc workspace.require
    ## `workspace.require`

    ```nix
    workspace.require packages
    ```

    Adds the Nix `packages` needed by this test to its runtime environment.
    Keep dependencies with the test that invokes them.
    */
    require = packages: {
      type = "require";
      inherit packages;
    };
  };

  runtime = /* python */ ''
    import os

    def write_file(fixture, action):
        path = os.path.join(fixture, action["path"])
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as file:
            file.write(action["content"])
  '';
}
