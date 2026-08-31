# Fixtures And Assertions

Fixtures are the interfaces available to a test callback. They keep tests
focused on observable behavior instead of backend implementation details.

Request only the fixtures a test uses:

```nix
test."service is healthy" = { machine }: [
  (machine.configure { modules = [ serviceModule ]; })
  (machine.service "example.service").start
  (expect (machine.service "example.service")).toBeActive
  ((expect (machine.http.get "http://localhost/health")).toHaveStatus 200)
];
```

## Core Fixtures

| Fixture | Use it to |
| --- | --- |
| `terminal` | Open and interact with a local terminal application |
| `machine` | Configure and control one NixOS VM |
| `machines` | Configure and control named NixOS VMs |
| `filesystem` | Prepare mutable files and observe machine paths |
| `service` | Start, stop, restart, and reload services |
| `network` | Locate endpoints and partition named machines |
| `http` | Observe idempotent requests or send one request once |
| `user` | Locate users and run commands as a user |
| `container` | Locate and control declarative NixOS containers |
| `browser` | Interact through accessibility-oriented browser locators |
| `desktop` | Locate windows and text and send desktop input |
| `result` | Inspect saved command and HTTP results |

`expect` is a module argument, not a test fixture. Import it at module scope and
use it with targets returned by fixtures.

## Locators

A locator describes what to observe without performing the assertion itself:

```nix
terminal.getByText "ready"
machine.service "example.service"
machine.file "/run/example/ready"
machine.http.get "http://localhost/health"
```

Prefer semantic locators over shell commands when both express the same public
behavior. They produce clearer tests and diagnostics.

## Matchers

Matchers live under `expect` and accept compatible locators or targets:

```nix
(expect (terminal.getByText "ready")).toBeVisible
(expect (machine.service "example.service")).toBeActive
(expect (machine.file "/run/example/state")).toHaveContent "ready"
(expect (machine.http.get "http://localhost/health")).toHaveStatus 200
```

Observable-state matchers retry until they pass or the timeout expires. They do
not repeat preceding side effects.

## Commands As An Escape Hatch

Use commands when no semantic locator describes the behavior:

```nix
(machine.command "example status")
(expect (machine.command "example is-ready")).toEventuallySucceed
(expect (machine.command "example forbidden-operation")).toFail
```

`machine.command` as a standalone action runs once. Command matchers retry, so
only use them for safe observations.

## Saved Results

Use `machine.run` or `http.send` when an operation has side effects. Save its
result once, then make assertions without repeating the operation:

```nix
test."creates an item once" = { machine, result }: [
  (machine.run {
    command = "example create";
    saveAs = "create";
  })
  ((expect (result.command "create")).toHaveExitCode 0)
  ((expect (result.stdout "create")).toContainStdout "created")
];
```

See the [guides](guides/README.md) for complete workflows and the
[API reference](reference/README.md) for exact signatures.
