# Fixtures

Fixtures are the interfaces a test uses to interact with the behavior under
test. A test callback selects the fixtures it needs and returns an ordered list
of actions:

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

The framework provides two fixtures for testing user-facing boundaries:

- `terminal` drives applications through a real pseudo-terminal.
- `vm` configures and tests a complete NixOS machine.

The `workspace` and `expect` fixtures support both styles. Fixture plugins
compose the built-ins into interfaces that express your application's
vocabulary.

## Terminal Fixture

Use `terminal` when the behavior is visible to someone interacting with a
command-line or terminal application. The fixture launches the application in a
real pseudo-terminal and observes a terminal-cell emulator, without requiring
application-specific hooks or parsing log files.

```nix
(test "opens a file" (
  { terminal, workspace, expect, ... }:
  [
    (workspace.require [ configuredEditor ])
    (workspace.writeFile "example.txt" "hello\n")
    (terminal.open "editor ${workspace.path}/example.txt")

    ((expect (terminal.getByText "hello")).toBeVisible)
    (terminal.press "<esc>")
  ]
))
```

### Text Locators

Use `terminal.getByText` when the behavior is that text becomes visible:

```nix
((expect (terminal.getByText "ready")).toBeVisible)
```

The assertion retries until the text appears or the test timeout expires. This
keeps synchronization tied to observable behavior rather than arbitrary sleeps.

### Region Locators

Use `terminal.getByRegion` when exact layout and terminal-cell content matter:

```nix
((expect (terminal.getByRegion {
  left = 0;
  top = 2;
  width = 40;
  height = 2;
})).toEqual ''
  Name                  Status
  example               ready
'')
```

Coordinates are zero-based. Leading spaces and Unicode characters are
preserved. Prefer a text locator when it expresses the same behavior, because
it is less coupled to presentation details.

### Keyboard Input

Use `terminal.press` to send literal text or named keys:

```text
<leader> <space> <esc> <escape> <enter> <cr> <tab> <bs>
```

Use `terminal.print` to write the current terminal grid to the build log while
debugging.

See the [Terminal API](reference/terminal.md) for every action, locator, and
matcher.

## Machine Fixture

Use `vm` when behavior depends on services, users, permissions, networking, or
the interaction between parts of a NixOS configuration. A test containing
`vm.configure` runs through the NixOS test driver.

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

### Command Matchers

- `toSucceed` runs a command once and requires success.
- `toEventuallySucceed` retries until success or timeout.
- `toFail` runs a command once and requires failure.

Use `toEventuallySucceed` for asynchronous state such as service activation or
file creation. Use a one-shot matcher when retrying could hide an ordering
problem.

The machine backend delegates to `pkgs.testers.runNixOSTest`. See the
[Machine API](reference/machine.md) for exact signatures.

## Workspace Fixture

The `workspace` fixture provides an isolated directory for each terminal test:

```nix
[
  (workspace.require [ my-package ])
  (workspace.writeFile "config.toml" config)
  (terminal.open "my-command --config ${workspace.path}/config.toml")
]
```

Use `workspace.require` to keep runtime dependencies beside the test that needs
them. Use `workspace.path` only in runtime values such as terminal commands; the
runner replaces it with the actual temporary path.

## Expect Fixture

The `expect` fixture dispatches based on its target:

- A terminal locator creates a retrying terminal assertion.
- A command string creates a machine command assertion.

This keeps assertions consistent while allowing each testing boundary to use
the synchronization behavior appropriate to it.

## Plugins

Plugins are custom fixtures built from the fixture set. They are ordinary Nix
values, not a separate package format or runtime system. Use them to hide
repeated setup and expose actions in the language of your application.

### Create a Fixture

Define a function that accepts the built-in fixtures and returns an attribute
set. The returned values can be functions, locators, assertions, actions, or
lists of actions:

```nix
makeApp = { terminal, workspace, expect, ... }: {
  openProject = name: [
    (workspace.writeFile "${name}/project.txt" "ready\n")
    (terminal.open "my-app ${workspace.path}/${name}")
  ];

  expectReady =
    (expect (terminal.getByText "ready")).toBeVisible;
};
```

Dependencies are explicit in the function arguments, so a fixture can be
understood and tested independently of the cases that use it.

### Extend `test`

Wrap the built-in `test` function and merge your fixture into the set passed to
the callback:

```nix
tests =
  { test, ... }:
  let
    makeApp = { terminal, workspace, expect, ... }: {
      openProject = name: [
        (workspace.writeFile "${name}/project.txt" "ready\n")
        (terminal.open "my-app ${workspace.path}/${name}")
      ];

      expectReady =
        (expect (terminal.getByText "ready")).toBeVisible;
    };

    testWithApp = name: callback:
      test name (fixtures:
        callback (fixtures // { app = makeApp fixtures; }));
  in
  [
    (testWithApp "opens a project" (
      { app, ... }:
      app.openProject "example" ++ [ app.expectReady ]
    ))
  ];
```

The callback receives `app` alongside the built-in fixtures. Nix's `//`
operator is the fixture composition mechanism.

### Reuse Fixtures

Move a reusable constructor into its own Nix module:

```nix
# tests/fixtures/app.nix
{ terminal, workspace, expect, ... }:
{
  open = file: [
    (workspace.writeFile file "ready\n")
    (terminal.open "my-app ${workspace.path}/${file}")
  ];

  expectReady =
    (expect (terminal.getByText "ready")).toBeVisible;
}
```

Import it while extending the fixture set:

```nix
let
  testWithApp = name: callback:
    test name (fixtures:
      callback (fixtures // {
        app = import ./tests/fixtures/app.nix fixtures;
      }));
in
[
  (testWithApp "shows status" ({ app, ... }:
    app.open "status.txt" ++ [ app.expectReady ]))
]
```

The same pattern can compose several fixture modules. Give each fixture a
distinct attribute name and merge them into the callback's fixture set.

### Setup and Cleanup

Tests are ordered action lists. A custom fixture can expose reusable setup
actions that a test places before its behavior and assertions:

```nix
{
  setup = [
    (workspace.require [ package ])
    (workspace.writeFile "config.toml" config)
  ];
}
```

There is currently no custom fixture lifecycle or automatic teardown API.
Terminal processes and temporary workspaces are cleaned up by the runner. A
custom resource that needs additional cleanup must model it explicitly in the
test's actions or in its execution backend.

### Custom Testing Boundaries

Application fixtures compose existing actions. Supporting a completely new
testing boundary requires three framework pieces:

1. Nix fixtures that construct serializable actions and locators.
2. A runner that executes those actions inside a derivation.
3. Dispatch logic that selects the runner for matching tests.

This is how the terminal and machine fixtures differ internally. See
[Architecture](architecture.md) for the current execution model.
