# Getting Started

## Flake-parts

Add the input and import its module:

```nix
{
  inputs.tests.url = "github:example/tests";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.tests.flakeModules.default ];

      perSystem =
        { pkgs, ... }:
        {
          tests =
            { test, ... }:
            [
              (test "shows ready" (
                { terminal, workspace, expect, ... }:
                [
                  (workspace.require [ pkgs.hello ])
                  (terminal.open "hello")
                  ((expect (terminal.getByText "Hello")).toBeVisible)
                ]
              ))
            ];
        };
    };
}
```

Each test name is preserved as an individual check, including spaces:

```sh
nix build '.#checks.aarch64-linux."shows ready"' --no-link
```

Run every check with:

```sh
nix flake check
```

## Plain Flakes

Without flake-parts, call `lib.mkTests` directly:

```nix
checks.${system} = inputs.tests.lib.mkTests { inherit pkgs; } (
  { test, ... }:
  [
    (test "shows ready" ({ terminal, workspace, expect, ... }: [
      (workspace.require [ pkgs.hello ])
      (terminal.open "hello")
      ((expect (terminal.getByText "Hello")).toBeVisible)
    ]))
  ]
);
```

The callback receives four fixtures:

- `terminal` controls a pseudo-terminal and creates terminal locators.
- `workspace` creates isolated files and supplies runtime packages.
- `expect` creates retrying terminal or machine assertions.
- `vm` configures the NixOS machine backend.

The callback returns an ordered list of actions. Nix evaluates the list while
constructing the check, and the generated runner executes it during the build.
