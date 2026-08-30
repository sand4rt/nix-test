# Fixtures

Fixtures are the interfaces available to a test callback. Nix Tests provides
four built-ins: `terminal`, `machine`, `workspace`, and `expect`.

Declare only the fixtures a test uses. The framework passes that exact subset,
so strict callback argument sets do not need `...`.

Suite-wide timeout and terminal dimensions are configured separately with
`test.configure`; they are not fixtures or runtime actions.

```nix
test."shows ready" = { terminal, expect }: [
  (terminal.open my-package)
  (expect.toBeVisible (terminal.getByText "ready"))
];
```

## Terminal Fixture

`terminal` drives a real pseudo-terminal and observes its terminal-cell grid.
Use it for command-line and terminal applications.

```nix
test."opens a file" = { terminal, workspace, expect }: [
  (workspace.writeFile "example.txt" "hello\n")
  (terminal.open "${lib.getExe configuredEditor} ${workspace.path}/example.txt")
  (expect.toBeVisible (terminal.getByText "hello"))
  (terminal.press "<esc>")
];
```

### Text Locators

Use a text locator when visible content is the behavior under test:

```nix
expect.toBeVisible (terminal.getByText "ready")
```

The matcher retries until the text appears or the timeout expires.

### Region Locators

Use a region locator when exact layout matters:

```nix
expect.toEqual {
  actual = terminal.getByRegion {
    left = 0;
    top = 2;
    width = 40;
    height = 2;
  };
  expected = ''
    Name                  Status
    example               ready
  '';
}
```

Coordinates are zero-based. Prefer text locators when layout is not part of the
behavior being tested.

### Keyboard Input

`terminal.press` accepts literal text and these named keys:

```text
<leader> <space> <esc> <escape> <enter> <cr> <c-w> <tab> <bs>
```

Use `terminal.print` to include the current grid in the build log.

## Machine Fixture

`machine` configures a complete NixOS test machine. Use it for services, users,
permissions, networking, and module interactions.

```nix
test."service starts" = { machine, expect }: [
  (machine.configure {
    modules = [ serviceModule ];
  })
  (machine.command "systemctl start example.service")
  (expect.toEventuallySucceed (machine.command "systemctl is-active example.service"))
  (expect.toFail (machine.command "pgrep forbidden-process"))
];
```

- `machine.command` runs once, prints stdout, and fails on a non-zero exit.
- `toEventuallySucceed` retries until success or timeout.
- `toFail` runs a command once and requires failure.

The machine fixture implements the terminal fixture interface, so the same
terminal interactions work on either backend:

```nix
[
  (machine.open "nvim flake.nix")
  (machine.press ":Neotest summary")
  (machine.press "<enter>")
  (expect.toBeVisible (machine.getByText "checks"))
  machine.print
]
```

Use this form when the application needs a complete NixOS environment or a
running Nix daemon.

## Workspace Fixture

`workspace` provides an isolated mutable directory for terminal tests:

```nix
[
  (workspace.writeFile "config.toml" config)
  (terminal.open "${lib.getExe my-package} --config ${workspace.path}/config.toml")
]
```

`workspace.path` is a runtime placeholder. Pass packages directly to
`terminal.open`, or use `lib.getExe` in command strings that include arguments.

## Expect Fixture

`expect` exposes Nix-style matcher functions:

```nix
expect.toBeVisible locator
expect.toEqual { actual = locator; expected = text; }
expect.toEventuallySucceed (machine.command command)
expect.toFail (machine.command command)
```

Unary matchers accept their target directly. Matchers with several values use a
named attribute set so argument meaning remains clear.

## Plugins

Plugins add application-specific fixtures and matchers through mergeable
flake-parts options. Tests consume the additions exactly like built-ins.

### Custom Fixture

```nix
testing.fixtures.app = inputs.tests.lib.mkFixture (_fixtures: {
  status = name:
    inputs.tests.lib.mkLocator {
      type = "appStatus";
      inherit name;
    };
});
```

The factory receives the complete fixture set. Its return value is injected as
`app` into test callbacks. Fixture definitions may refer to one another through
the recursive fixture set. Use `lib.mkLocator` when a fixture exposes a value
for custom matchers. Use `lib.mkTarget` for non-locator matcher inputs, such as
commands or protocol requests.

A reusable locator file registers locators under their owning fixture:

```nix
# src/locators.nix
{ mkLocator, ... }:
{
  testing.locators.app.getByStatus = status: mkLocator {
    type = "appStatus";
    inherit status;
  };
}
```

Import it from the per-system scope. Its locators are merged into `app`:

```nix
perSystem = { ... }: {
  imports = [ ./src/locators.nix ];
};
```

### Custom Matcher

```nix
testing.matchers.toBeReady = inputs.tests.lib.mkMatcher {
  accepts = [ "appStatus" ];
  run = _fixtures: target:
    inputs.tests.lib.mkAction "assertAppStatus" {
      inherit (target) name;
    };
};
```

`mkMatcher` validates the target before running the matcher. `mkAction` creates
the serializable action consumed by a custom backend. The matcher becomes
available on `expect`:

```nix
test."reports ready" = { app, expect }: [
  (expect.toBeReady (app.status "ready"))
];
```

### Reusable Plugin

Put fixture and matcher declarations in one flake-parts module:

```nix
# src/plugin.nix
{ ... }:
{
  perSystem = { ... }: {
    testing.fixtures.app = inputs.tests.lib.mkFixture (_fixtures: {
      status = name:
        inputs.tests.lib.mkLocator {
          type = "appStatus";
          inherit name;
        };
    });

    testing.matchers.toBeReady = inputs.tests.lib.mkMatcher {
      accepts = [ "appStatus" ];
      run = _fixtures: target:
        inputs.tests.lib.mkAction "assertAppStatus" {
          inherit (target) name;
        };
    };
  };
}
```

Import it once:

```nix
imports = [
  inputs.tests.flakeModules.default
  ./src/plugin.nix
];
```

Individual test files need no plugin import.

### Plain Flakes

Pass plugin definitions to `lib.mkTests`:

```nix
checks.${system} = inputs.tests.lib.mkTests {
  inherit pkgs test;
  fixtures = {
    app = inputs.tests.lib.mkFixture (
      fixtures: import ./fixtures/app.nix fixtures
    );
  };
  matchers = {
    toBeReady = inputs.tests.lib.mkMatcher {
      accepts = [ "appStatus" ];
      run = _fixtures: target:
        inputs.tests.lib.mkAction "assertAppStatus" {
          inherit (target) name;
        };
    };
  };
};
```

There is no custom fixture setup or teardown lifecycle. Fixtures return values
and reusable action lists; terminal processes and workspaces are cleaned up by
the runner.
