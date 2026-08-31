# Nix Test

Nix Test is a declarative testing framework for user-facing behavior in Nix.
Tests define the environment, interactions, and expectations together, then run
as regular flake checks.

Use Nix Test to exercise:

- terminal applications through a real pseudo-terminal
- NixOS services and machines through the NixOS test driver
- files, users, containers, networks, and HTTP endpoints
- browser and desktop behavior
- custom fixtures, locators, and matchers

```nix
{ pkgs, expect, ... }:
{
  test."shows a greeting" = { terminal }: [
    (terminal.open pkgs.hello)
    (expect (terminal.getByText "Hello")).toBeVisible
  ];
}
```

Start with [Getting Started](getting-started.md), learn the test model in
[Writing Tests](writing-tests.md), or browse the [API Reference](reference/README.md).
