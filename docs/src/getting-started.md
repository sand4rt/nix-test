# Getting Started

This guide adds Nix Test to a flake, puts the test in its own file, and runs it
as a normal flake check.

## Add Nix Test

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    tests = {
      url = "github:sand4rt/nix-test";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.tests.flakeModules.default ];
      systems = [ "x86_64-linux" ];

      perSystem = { ... }: {
        imports = [ ./tests/hello.test.nix ];
      };
    };
}
```

Change the system when your machine uses another supported architecture.

## Write A Test

Create `tests/hello.test.nix`:

```nix
{ pkgs, expect, ... }:
{
  test."shows a greeting" = { terminal }: [
    (terminal.open pkgs.hello)
    (expect (terminal.getByText "Hello")).toBeVisible
  ];
}
```

The attribute name is both the test name and its flake check name. The callback
requests the fixtures it needs and returns actions in execution order.

## Run The Test

```sh
nix build '.#checks.x86_64-linux."shows a greeting"' --no-link -L
```

Run all checks for the current system with:

```sh
nix flake check
```

Next, read [Writing Tests](writing-tests.md) for steps, assertions, configuration,
and separate test files. If you do not use flake-parts, see
[Running Tests](running-tests.md#without-flake-parts).
