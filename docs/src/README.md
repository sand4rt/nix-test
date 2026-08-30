# Nix Tests

Nix Tests is a declarative testing framework for testing user-facing behavior
in Nix. It combines a Playwright-style API with Testing Library's philosophy.

Tests exercise observable behavior through focused fixtures. Each case becomes
an ordinary Nix derivation that can be exposed as a flake check.

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
[API Reference](reference/README.md) for exact signatures and defaults.

## Fixtures

### Terminal Fixture

The `terminal` fixture tests command-line and terminal applications through a
real pseudo-terminal. It can launch programs, send keyboard input, locate
visible text, and select exact terminal-cell regions.

Use it when the behavior under test is visible to someone interacting with a
terminal application.

[Use the terminal fixture](fixtures.md#terminal-fixture)

### Machine Fixture

The `vm` fixture tests complete NixOS machines through the NixOS test driver. It
can configure the machine and assert command results, including commands that
must eventually succeed.

Use it when the behavior depends on services, users, permissions, networking,
or the interaction between multiple parts of a NixOS configuration.

[Use the machine fixture](fixtures.md#machine-fixture)

### Workspace Fixture

The `workspace` fixture provides an isolated directory, test files, and runtime
packages for terminal tests.

[Use the workspace fixture](fixtures.md#workspace-fixture)

### Expect Fixture

The `expect` fixture creates assertions for terminal locators and machine
commands. Retrying matchers synchronize tests with observable behavior.

[Use the expect fixture](fixtures.md#expect-fixture)

## Plugins

Fixtures are ordinary Nix values, so you can build application-specific
fixtures on top of the built-ins. A custom fixture can combine setup actions,
locators, assertions, and other fixtures behind a small interface, then be
merged into the fixture set passed to each test.

Use custom fixtures to express your application's vocabulary and keep repeated
setup out of individual tests. New execution backends can also be added by
extending the framework with their own actions and runner.

[Create fixture plugins](fixtures.md#plugins)

## Principles

- Test through public, user-facing interfaces.
- Use the fixture that matches the user-facing boundary under test.
- Retry observable assertions instead of guessing with sleeps.
- Keep runtime dependencies with the test that needs them.
- Emit useful terminal state when an assertion fails.
