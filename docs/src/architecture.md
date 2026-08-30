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

Backend-specific implementations live under `lib/terminal` and `lib/vm`.
Shared test construction and workspace behavior live under `lib`.

This separation keeps test declarations stable while allowing each backend to
use the runtime best suited to its boundary.

## Related Infrastructure

The library composes existing Nix infrastructure rather than replacing it:

- [NixOS tests](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- `nixos/lib/test-driver`
- `nixos/lib/testing`
- `pkgs.testers.runNixOSTest`
