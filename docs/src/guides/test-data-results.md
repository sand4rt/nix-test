# Test Data And Results

## Isolated Workspaces

`filesystem` prepares mutable files under an isolated runtime directory:

```nix
test."reads configuration" = { terminal, filesystem }: [
  (filesystem.writeFile "config.toml" ''
    greeting = "Hello"
  '')
  (terminal.open "${application} --config ${filesystem.root}/config.toml")
  (expect (terminal.getByText "Hello")).toBeVisible
];
```

Paths are relative to the filesystem root. Absolute paths and parent traversal are
rejected during Nix evaluation. Other actions include `makeDirectory`,
`copyFile`, `copyTree`, `symlink`, `setMode`, and `remove`.

## Saved Command Results

Run side-effecting commands once and save their output:

```nix
test."creates an item once" = { machine, result }: [
  (machine.configure { })
  (machine.run {
    command = "example create";
    saveAs = "create";
  })
  ((expect (result.command "create")).toHaveExitCode 0)
  ((expect (result.stdout "create")).toContainStdout "created")
];
```

## Saved HTTP Results

Use `http.send` for mutating requests:

```nix
test."creates an item through HTTP" = { machine, http, result }: [
  (machine.configure { modules = [ apiModule ]; })
  (http.send machine {
    method = "POST";
    url = "http://localhost/items";
    body = ''{"name":"example"}'';
    saveAs = "create-item";
  })
  ((expect (result.command "create-item")).toHaveExitCode 0)
  ((expect (result.stdout "create-item")).toContainStdout "created")
];
```

Saved-result assertions never repeat the original side effect.
