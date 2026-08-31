# Terminal Applications

The `terminal` fixture runs a command in a real pseudo-terminal. Use it for CLI
and TUI behavior that depends on terminal dimensions, keyboard input, cursor
movement, or visible screen contents.

```nix
test."opens a document" = { terminal, filesystem }: [
  (filesystem.writeFile "example.txt" "hello\n")
  (terminal.open "${editor} ${filesystem.root}/example.txt")
  (expect (terminal.getByText "hello")).toBeVisible
  (terminal.press "<esc>")
];
```

## Open A Program

Pass a package to resolve its executable with `lib.getExe`, which uses
`meta.mainProgram` when set and otherwise the package's main name:

```nix
terminal.open pkgs.hello
```

Use a command string when arguments are required:

```nix
terminal.open "${pkgs.lib.getExe application} --config ${filesystem.root}/config.toml"
```

## Send Keyboard Input

Literal text and named keys may be combined:

```nix
(terminal.press "hello<enter>")
(terminal.press "<esc>")
(terminal.press "<esc>:wq<enter>")
```

## Locate Visible Text

```nix
  (expect (terminal.getByText "ready")).toBeVisible
  ((expect (terminal.getByRegion {
  left = 0;
  top = 0;
  width = 12;
  height = 1;
  })).toEqual "Status: ready")
```

Text observations retry automatically. Add `terminal.print` to emit the current
screen in the build log while debugging.
