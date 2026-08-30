# Debugging

Build a focused check with verbose logs:

```sh
nix build '.#checks.aarch64-linux."shows ready"' --no-link -L
```

Add `terminal.print` after an action to inspect the current terminal grid:

```nix
[
  (terminal.press "<enter>")
  terminal.print
]
```

Terminal text failures include the missing text and visible terminal state.
Region failures also include the expected and observed regions. Inspect a
previous build log with:

```sh
nix log /nix/store/<test-derivation>
```

## Avoid Sleeps

Visible terminal assertions retry until their backend times out. Synchronize on
visible state:

```nix
expect.toBeVisible (terminal.getByText "ready")
```

For machine tests, use `machine.command` directly for one-shot commands and
`toEventuallySucceed` when the state changes asynchronously. Direct
`machine.command` actions print their standard output in the test log.
