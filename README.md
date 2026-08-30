# Nix Tests

> A declarative framework for testing user-facing behavior in Nix, combining a
> Playwright-style API with Testing Library's philosophy.

## Capabilities

- Exercise terminal applications through a real pseudo-terminal.
- Test NixOS behavior through the NixOS test driver.
- Locate visible terminal text or exact terminal-cell regions.
- Retry assertions until observable state is ready, without arbitrary sleeps.
- Create isolated workspaces with test-specific files and runtime packages.
- Expose every test as a regular flake check.
- Print useful terminal state when an assertion fails.

## Usage

Add the input and import its flake-parts module:

```nix
{
  inputs.tests.url = "github:example/nix-tests";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.tests.flakeModules.default ];

      perSystem =
        { pkgs, ... }:
        {
          tests =
            { test, ... }:
            [
              (test "shows greeting" (
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

Run all tests:

```sh
nix flake check
```

Or run one test by its name:

```sh
nix build '.#checks.aarch64-linux."shows greeting"' --no-link -L
```

See the [documentation](docs/src/README.md),
[getting-started guide](docs/src/getting-started.md), and generated
[API reference](docs/src/reference/README.md) for more information.
