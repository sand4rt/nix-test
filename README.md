# Nix Tests

A declarative testing framework for testing user-facing behavior in Nix.
It combines a Playwright-style API with Testing Library's philosophy.

```nix
(test "shows ready" ({ terminal, expect, ... }: [
  (terminal.open "my-command")
  ((expect (terminal.getByText "ready")).toBeVisible)
]))
```

Import `flakeModules.default` with flake-parts, or call `lib.mkTests` from a
plain flake. Tests become regular flake checks:

```sh
nix flake check
```

- [Documentation](docs/src/README.md)
- [Getting started](docs/src/getting-started.md)
- [API reference](docs/src/reference/api.md)
- [License](LICENSE)
