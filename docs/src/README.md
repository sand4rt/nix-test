# Nix Test

Nix Test is a declarative framework for testing user-facing behavior in Nix.

Tests exercise observable behavior through focused fixtures. Each case becomes
an ordinary Nix derivation that can be exposed as a flake check.

```nix
test."shows ready" = { terminal, expect }: [
  (terminal.open my-package)
  (expect.toBeVisible (terminal.getByText "ready"))
];
```

Start with [Getting Started](getting-started.md), then use the generated
[API Reference](reference/README.md) for exact signatures and defaults.

When a machine test needs inspection beyond build logs, the [Debugging
guide](debugging.md) covers the interactive NixOS driver, guest shells, SSH,
port forwarding, and persistent VM state.

## Fixtures

### Terminal

The `terminal` fixture tests command-line and terminal applications through a
real pseudo-terminal. It can launch programs, send keyboard input, locate
visible text, and select exact terminal-cell regions.

Use it when the behavior under test is visible to someone interacting with a
terminal application.

[Use Terminal](fixtures.md#terminal)

### Machine

The `machine` fixture tests complete NixOS machines through the NixOS test
driver. It implements the terminal fixture interface and extends it with
machine configuration and command assertions, including commands that must
eventually succeed or fail.

Use it when the behavior depends on services, users, permissions, networking,
or the interaction between multiple parts of a NixOS configuration. Every
machine test includes `machine.configure`, which selects the machine backend.

[Use Machine](fixtures.md#machine)

### Observable System State

Semantic service, filesystem, endpoint, HTTP, user, and container locators
describe what users and administrators can observe. Their matchers retry
automatically, without public `waitFor*` operations.

[Use semantic machine fixtures](fixtures.md#observable-system-state)

### Workspace

The `workspace` fixture provides an isolated directory and mutable test files
for terminal and machine tests.

[Use Workspace](fixtures.md#workspace)

### Expect

The `expect` fixture creates assertions for terminal locators and machine
commands. Retrying matchers synchronize tests with observable behavior.

[Use Expect](fixtures.md#expect)

## Plugins

Fixtures are ordinary Nix values, so you can build application-specific
fixtures on top of the built-ins. A custom fixture can combine setup actions,
locators, assertions, and other fixtures behind a small interface, then be
merged into the fixture set passed to each test.

Use custom fixtures to express your application's vocabulary and keep repeated
setup out of individual tests. Custom actions must be understood by the
selected built-in runner.

[Create fixture plugins](fixtures.md#plugins)

## Principles

- Test through public, user-facing interfaces.
- Use the fixture that matches the user-facing boundary under test.
- Retry observable assertions instead of guessing with sleeps.
- Pass packages directly to `terminal.open` when no arguments are needed.
- Emit useful terminal state when an assertion fails.
