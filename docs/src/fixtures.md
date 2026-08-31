# Fixtures And Assertions

Fixtures are the interfaces available to a test callback. They keep tests
focused on observable behavior instead of backend implementation details.

Request only the fixtures a test uses:

```nix
test."service is healthy" = { machine, service, expect }: [
  (machine.configure { modules = [ serviceModule ]; })
  (service.start (machine.service "example.service"))
  (expect.toBeActive (machine.service "example.service"))
  (expect.toHaveStatus 200 (machine.http.get "http://localhost/health"))
];
```

## Core Fixtures

| Fixture | Use it to |
| --- | --- |
| `terminal` | Open and interact with a local terminal application |
| `machine` | Configure and control one NixOS VM |
| `machines` | Configure and control named NixOS VMs |
| `workspace` | Prepare isolated mutable files and directories |
| `service` | Start, stop, restart, and reload services |
| `filesystem` | Locate files, directories, links, and mounts |
| `network` | Locate endpoints and partition named machines |
| `http` | Observe idempotent requests or send one request once |
| `user` | Locate users and run commands as a user |
| `container` | Locate and control declarative NixOS containers |
| `browser` | Interact through accessibility-oriented browser locators |
| `desktop` | Locate windows and text and send desktop input |
| `result` | Inspect saved command and HTTP results |
| `expect` | Apply matchers to observable targets |

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
expect.toBeVisible (terminal.getByText "ready")
expect.toBeActive (machine.service "example.service")
expect.toHaveContent (machine.file "/run/example/state") "ready"
expect.toHaveStatus 200 (machine.http.get "http://localhost/health")
```

Observable-state matchers retry until they pass or the timeout expires. They do
not repeat preceding side effects.

## Commands As An Escape Hatch

Use commands when no semantic locator describes the behavior:

```nix
(machine.command "example status")
(expect.toEventuallySucceed (machine.command "example is-ready"))
(expect.toFail (machine.command "example forbidden-operation"))
```

`machine.command` as a standalone action runs once. Command matchers retry, so
only use them for safe observations.

## Saved Results

Use `machine.run` or `http.send` when an operation has side effects. Save its
result once, then make assertions without repeating the operation:

```nix
test."creates an item once" = { machine, result, expect }: [
  (machine.configure { })
  (machine.run {
    command = "example create";
    saveAs = "create";
  })
  (expect.toHaveExitCode 0 (result.command "create"))
  (expect.toContainStdout (result.stdout "create") "created")
];
```

See the [guides](guides/README.md) for complete workflows and the
[API reference](reference/README.md) for exact signatures.
