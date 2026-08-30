# Terminal Tests

Terminal tests launch the application in a real pseudo-terminal and observe a
terminal-cell emulator. They do not need application-specific hooks or parse
log files.

```nix
(test "opens a file" (
  { terminal, workspace, expect, ... }:
  [
    (workspace.require [ configuredEditor ])
    (workspace.writeFile "example.txt" "hello\n")
    (terminal.open "editor ${workspace.path}/example.txt")

    ((expect (terminal.getByText "hello")).toBeVisible)
    (terminal.press "<esc>")
  ]
))
```

## Text Locators

Use `terminal.getByText` when the important behavior is that text becomes
visible:

```nix
((expect (terminal.getByText "ready")).toBeVisible)
```

The assertion retries until the text appears or the test timeout expires.

## Region Locators

Use `terminal.getByRegion` when layout and exact cell content matter:

```nix
((expect (terminal.getByRegion {
  left = 0;
  top = 2;
  width = 40;
  height = 2;
})).toEqual ''
  Name                  Status
  example               ready
'')
```

Coordinates are zero-based. Leading spaces and Unicode characters are
preserved. Avoid region assertions when a text assertion expresses the same
behavior more robustly.

## Input

`terminal.press` accepts text and these named keys:

```text
<leader> <space> <esc> <escape> <enter> <cr> <tab> <bs>
```

Use `terminal.print` to put the current grid in the build log while debugging.
