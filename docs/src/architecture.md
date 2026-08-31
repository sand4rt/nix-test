# Architecture

```text
Nix test declaration
        |
        v
recursive fixture set
        |
        +-- terminal fixture --+
        |                      +-- terminal fixture interface
        +-- machine fixture ---+   (open, press, print, getByText, getByRegion)
        |                          + semantic system-state fixtures
        +-- named machines -------- per-node modules, actions, and locators
        v
ordered action values
        |
        +-- no machineConfigure action --> JSON action document
        |                           --> pexpect/pyte PTY runner
        |
        +-- machineConfigure action ----> NixOS modules and test-driver script
                                    --> NixOS test driver
```

Nix functions construct ordered action values. A test containing the action
produced by `machine.configure` or `machines.configure` selects the machine
backend; every other test uses the standalone terminal backend. Terminal checks encode their actions as JSON and
execute generated Python runtime modules in a derivation. Machine checks add the
configured modules to a NixOS test and render the remaining actions into its
test-driver script.

Consequently, any executable machine-backed action requires one of those
configuration actions. Merely constructing a machine locator does not select a
backend.

Test orchestration and plugin resolution live under `core`. Every built-in
fixture owns a top-level directory containing its fixture, matchers, locators,
runtime support, and colocated tests as applicable. `terminal` and `machine`
provide the two execution boundaries; semantic fixtures such as `service`,
`filesystem`, `http`, and `browser` build on the machine boundary without being
implemented inside it.

The built-in fixture directories are:

```text
browser/     container/   desktop/      expect/
filesystem/  http/        machine/      network/
result/      service/     step/         terminal/
user/        workspace/
```

`fixture.nix` defines the injected fixture. A fixture directory may additionally
contain `locators.nix`, `matchers.nix`, runtime modules, and colocated tests.
`machines` remains in `machine/fixture.nix` because it is the named-node view of
the same NixOS driver backend, not an independent fixture boundary.

Terminal and machine are registered through the same fixture-factory mechanism
as user plugins. Fixture factories are evaluated against one recursive fixture
set, then locators are merged into their owning fixtures. At that boundary,
both built-in backends are checked for the terminal fixture interface: `open`,
`press`, `print`, `getByText`, and `getByRegion`. Machine extends that interface
with NixOS configuration, command assertions, and a pattern locator. Built-in
fixture names are reserved; custom fixtures join the same recursive set.

The contract specifies the public operation names and whether each operation is
callable or an action. During evaluation, the framework checks that both
fixtures provide the required names, that callable operations are functions,
and that `print` is an action. Each backend still implements observation through
its native runtime: the standalone backend reads a `pyte` cell grid, while the
machine backend captures a `tmux` pane through the NixOS test driver.

Fixtures, actions, locators, other matcher targets, and matcher factories are
created with `lib.mkFixture`, `lib.mkAction`, `lib.mkLocator`, `lib.mkTarget`,
and `lib.mkMatcher`. These constructors validate value shape and matcher target
compatibility during Nix evaluation. The terminal fixture interface is an
internal contract for the two built-in backends; custom fixtures are not
required to implement it.

Semantic machine locators compile to retrying NixOS driver predicates. Actions
such as restart, reboot, input, and file staging execute once; only matcher
observations retry. Named steps compile to nested driver subtests.

This separation keeps test declarations stable while allowing each backend to
use the runtime best suited to its boundary.

## Related Infrastructure

The library composes existing Nix infrastructure rather than replacing it:

- [NixOS tests](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- `nixos/lib/test-driver`
- `nixos/lib/testing`
- `pkgs.testers.runNixOSTest`
