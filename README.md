# Nix Test

## Capabilities

- Exercise terminal applications through a real pseudo-terminal.
- Test NixOS behavior through the NixOS test driver.
- Locate visible terminal text or exact terminal-cell regions.
- Retry assertions until observable state is ready, without arbitrary sleeps.
- Create isolated workspaces with test-specific files.
- Extend the framework with custom fixtures, locators, and matchers.
- Expose every test as a regular flake check.
- Print useful terminal state when an assertion fails.

## Usage

Add the input and import its flake-parts module:

```nix
{
  inputs.tests.url = "github:sand4rt/nix-test";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.tests.flakeModules.default ];

      perSystem =
        { pkgs, ... }:
        {
          test."shows greeting" = { terminal, expect }: [
            (terminal.open pkgs.hello)
            (expect.toBeVisible (terminal.getByText "Hello"))
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
