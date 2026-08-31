# Test Data And Results

## Isolated Workspaces

`workspace` prepares mutable files under an isolated runtime directory:

```nix
test."reads configuration" = { terminal, workspace, expect }: [
  (workspace.writeFile "config.toml" ''
    greeting = "Hello"
  '')
  (terminal.open "${application} --config ${workspace.path}/config.toml")
  (expect.toBeVisible (terminal.getByText "Hello"))
];
```

Paths are relative to the workspace. Absolute paths and parent traversal are
rejected during Nix evaluation. Other actions include `makeDirectory`,
`copyFile`, `copyTree`, `symlink`, `setMode`, and `remove`.

## Saved Command Results

Run side-effecting commands once and save their output:

```nix
test."creates an item once" = { machine, result, expect }: [
  (machine.configure { })
  (machine.run {
    command = "example create";
    saveAs = "create";
  })
  (expect.toHaveExitCode 0 (result.command "create"))
  (expect.toContainStdout (result.stdout "create") "created")
];
```

## Saved HTTP Results

Use `http.send` for mutating requests:

```nix
test."creates an item through HTTP" = { machine, http, result, expect }: [
  (machine.configure { modules = [ apiModule ]; })
  (http.send machine {
    method = "POST";
    url = "http://localhost/items";
    body = ''{"name":"example"}'';
    saveAs = "create-item";
  })
  (expect.toHaveExitCode 0 (result.command "create-item"))
  (expect.toContainStdout (result.stdout "create-item") "created")
];
```

Saved-result assertions never repeat the original side effect.
