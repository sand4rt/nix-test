# Architecture

```text
Nix test declaration
        |
        v
action, locator, and assertion values
        |
        v
JSON action document
        |
        v
generated runtime runner
        |
        +-- terminal: pexpect, pyte, and a PTY
        +-- machine: NixOS test driver
```

Nix functions construct serializable action values. Terminal checks encode
those values as JSON and execute generated Python runtime modules in a
derivation. Machine checks translate command assertions into a NixOS test
script.

Test orchestration and plugin resolution live under `core`. Each backend keeps
its fixture, locators, assertions, matchers, and colocated tests together under
`terminal` or `machine`. The workspace fixture lives under `workspace`.

Terminal and machine are registered through the same fixture-factory mechanism
as user plugins. Built-in fixtures are reserved names, while custom fixtures are
merged into the same recursive fixture set.

Fixtures, actions, locators, other matcher targets, and matcher factories are
created with `lib.mkFixture`, `lib.mkAction`, `lib.mkLocator`, `lib.mkTarget`,
and `lib.mkMatcher`. Built-ins and plugins use these same constructors, so the
extension contract is validated during Nix evaluation.

This separation keeps test declarations stable while allowing each backend to
use the runtime best suited to its boundary.

## Related Infrastructure

The library composes existing Nix infrastructure rather than replacing it:

- [NixOS tests](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- `nixos/lib/test-driver`
- `nixos/lib/testing`
- `pkgs.testers.runNixOSTest`
