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

Terminal assertion failures include the expected value, the observed locator
value, and the full visible terminal state. Inspect a previous build log with:

```sh
nix log /nix/store/<test-derivation>
```

## Avoid Sleeps

Assertions already retry until the test timeout. Synchronize on visible state:

```nix
((expect (terminal.getByText "ready")).toBeVisible)
```

For machine tests, use `toEventuallySucceed` when the state changes
asynchronously.
