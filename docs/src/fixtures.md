# Fixtures

Fixtures are the interfaces available to a test callback. Built-ins cover
terminals, NixOS machines, workspaces, services, filesystems, networking, HTTP,
users, containers, browsers, desktops, saved results, and expectations.

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

## Terminal

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

## Machine

`machine` configures a complete NixOS test machine. Use it for services, users,
permissions, networking, and module interactions.

```nix
test."service starts" = { machine, service, expect }: [
  (machine.configure {
    modules = [ serviceModule ];
  })
  (service.start (machine.service "example.service"))
  (expect.toBeActive (machine.service "example.service"))
  (expect.toFail (machine.command "pgrep forbidden-process"))
];
```

- Service and other semantic matchers retry until success or timeout.
- `machine.command` runs once, prints stdout, and fails on a non-zero exit.
- `toEventuallySucceed` and `toFail` cover commands without semantic locators.

The machine fixture implements the terminal fixture interface, so the same
terminal interactions work on either backend:

```nix
[
  (machine.configure { })
  (machine.open "nvim flake.nix")
  (machine.press ":Neotest summary")
  (machine.press "<enter>")
  (expect.toBeVisible (machine.getByText "checks"))
  machine.print
]
```

Use this form when the application needs a complete NixOS environment or a
running Nix daemon. Every machine test must include `machine.configure`, even
when no additional NixOS modules are required; that action selects the machine
backend.

The fixture intentionally exposes a behavior-oriented subset of the
[NixOS test driver](https://nixos.org/manual/nixos/stable/#sec-nixos-tests).
Interactive driver consoles, QEMU monitor commands, fault injection, and raw
host-to-guest copying are not part of the declarative fixture API.

## Workspace

`workspace` provides an isolated mutable directory for terminal and machine
tests:

```nix
[
  (workspace.writeFile "config.toml" config)
  (terminal.open "${lib.getExe my-package} --config ${workspace.path}/config.toml")
]
```

`workspace.path` is a runtime placeholder. Pass packages directly to
`terminal.open` or `machine.open`, or use `lib.getExe` in command strings that
include arguments.

Workspace also provides `makeDirectory`, `copyFile`, `copyTree`, `symlink`,
`setMode`, and `remove`. Paths are relative to the isolated workspace; absolute
paths and parent traversal are rejected during Nix evaluation.

## Observable System State

Machine locators describe state. Matchers repeatedly observe that state until it
matches or the timeout expires; actions execute once.

```nix
let app = machine.service "example.service"; in [
  (expect.toBeActive app)
  (expect.toExist (machine.file "/run/example-ready"))
  (expect.toHaveContent (machine.file "/run/example-state") "ready")
  (expect.toBeReachable (machine.endpoint.tcp 8080))
  (expect.toHaveStatus 200 (machine.http.get "http://localhost:8080/health"))
  (service.restart app)
]
```

Service actions are `start`, `stop`, `restart`, and `reload`. Service matchers
include `toBeActive`, `toBeInactive`, `toBeFailed`, and `toHaveLog`.

Filesystem matchers include `toExist`, `toBeAbsent`, `toBeFile`,
`toBeDirectory`, `toBeSymlink`, `toBeMounted`, `toHaveContent`, `toPointTo`,
`toHaveMode`, and `toBeOwnedBy`.

Endpoint matchers are `toBeReachable` and `toBeUnreachable`. HTTP matchers
include `toHaveStatus`, `toHaveBody`, `toHaveHeader`, and `toHaveJsonValue`.

Users support `toExist`, `toBeAbsent`, `toBeMemberOf`, and `user.run`.
Containers support `start`, `stop`, `restart`, `run`, `toBeRunning`, and
`toBeStopped`.

## Saved Results

Use a one-shot action when a command or mutating request must execute exactly
once, then assert its saved result without repeating the side effect:

```nix
[
  (machine.run {
    command = "example create";
    saveAs = "create";
  })
  (expect.toHaveExitCode 0 (result.command "create"))
  (expect.toContainStdout (result.stdout "create") "created")
]
```

`http.send` similarly accepts `method`, `url`, `headers`, `body`, and `saveAs`.
Saved results provide `toHaveExitCode`, `toHaveStdout`, and `toContainStdout`.
Unlike observable-state matchers, saved-result assertions do not retry the
original action.

## Named Machines

```nix
test."client observes server" = { machines, expect }: let
  server = machines.node "server";
  client = machines.node "client";
in [
  (machines.configure {
    server.modules = [ serverModule ];
    client.modules = [ clientModule ];
  })
  (expect.toBeActive (server.service "example.service"))
  (expect.toSucceed (client.command "example-client server"))
]
```

Named machines expose the same command, terminal, service, filesystem,
endpoint, HTTP, user, and container APIs, plus `start`, `shutdown`, `reboot`,
and `crash`. `network.partition` and `network.heal` express partitions between
groups of named nodes.

## Steps

Use `test.step` to add nested diagnostic names:

```nix
(test.step "service becomes usable" [
  (expect.toBeActive (machine.service "example.service"))
  (expect.toHaveStatus 200 (machine.http.get "http://localhost/health"))
])
```

## Browser And Desktop

The browser fixture favors accessibility-oriented locators:

```nix
let button = browser.getByRole machine "button" { name = "Sign in"; }; in [
  (machine.configure { })
  (browser.configure machine)
  (browser.open machine "http://localhost/")
  (browser.fill (browser.getByLabel machine "Username") "example")
  (browser.click button)
  (expect.toBeVisible button)
]
```

Browser locators include role, label, placeholder, text, and title. Desktop
tests use `desktop.getByWindow` or `desktop.getByText`, plus keyboard, text, and
screenshot actions. These observations also retry through `expect.toBeVisible`.

## Expect

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

### Custom Fixtures

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
a typed action for the selected built-in runner to consume. The matcher becomes
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
