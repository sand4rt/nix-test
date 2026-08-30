# Machine Tests

A test containing `vm.configure` runs through the NixOS test driver. Use this
backend for services, users, permissions, networking, or other system behavior
that a standalone terminal process cannot represent.

```nix
(test "service starts" (
  { vm, expect, ... }:
  [
    (vm.configure {
      homeModules = [ serviceModule ];
    })

    (expect "systemctl --user start example.service").toSucceed
    (expect "systemctl --user is-active example.service").toEventuallySucceed
    (expect "pgrep forbidden-process").toFail
  ]
))
```

## Matchers

- `toSucceed` runs a command once and requires success.
- `toEventuallySucceed` retries until success or timeout.
- `toFail` runs a command once and requires failure.

Prefer `toEventuallySucceed` for asynchronous state such as service activation
or file creation. Prefer the one-shot matchers when retrying could hide a real
ordering problem.

The VM backend currently delegates to `pkgs.testers.runNixOSTest`. Container and
browser fixtures are not implemented.
