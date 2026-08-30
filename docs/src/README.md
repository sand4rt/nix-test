# Nix Tests

Nix Tests is a declarative testing framework for testing user-facing behavior
in Nix. It combines a Playwright-style API with Testing Library's philosophy.
Its current backends cover terminal applications and NixOS machines.

Tests exercise observable behavior through a real pseudo-terminal or the NixOS
test driver. Each case becomes an ordinary Nix derivation that can be exposed as
a flake check.

```nix
(test "shows ready" (
  { terminal, workspace, expect, ... }:
  [
    (workspace.require [ my-package ])
    (terminal.open "my-command")
    ((expect (terminal.getByText "ready")).toBeVisible)
  ]
))
```

Start with [Getting Started](getting-started.md), then use the generated
[API Reference](reference/api.md) for exact signatures and defaults.

## Principles

- Test through public, user-facing interfaces.
- Use a PTY for terminal behavior and a VM for system behavior.
- Retry observable assertions instead of guessing with sleeps.
- Keep runtime dependencies with the test that needs them.
- Emit useful terminal state when an assertion fails.
