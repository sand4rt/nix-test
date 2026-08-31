# Writing Tests

Tests are named attributes whose values are callbacks. A callback receives the
fixtures it requests and returns an ordered list of actions.

```nix
test."saves the document" = { terminal, workspace, expect }: [
  (workspace.writeFile "document.txt" "draft\n")
  (terminal.open "${editor} ${workspace.path}/document.txt")
  (expect.toBeVisible (terminal.getByText "draft"))
  (terminal.press "<esc>")
];
```

## Actions Run In Order

Each item in the returned list is an action. Setup, interaction, and assertions
are written in the same order a user or operator would perform them.

```nix
[
  (terminal.open application)
  (terminal.press "<enter>")
  (expect.toBeVisible (terminal.getByText "ready"))
]
```

## Fixtures

Fixtures describe the boundary under test. Request only what the test uses:

```nix
{ terminal, workspace, expect }:
```

Use `terminal` for local command-line applications and `machine` or `machines`
for NixOS VMs. Semantic fixtures such as `service`, `filesystem`, `network`,
`http`, and `user` build on the machine backend. See
[Fixtures and Assertions](fixtures.md).

## Locators And Assertions

Locators describe observable state; matchers assert against it:

```nix
(expect.toBeVisible (terminal.getByText "ready"))
(expect.toBeActive (machine.service "example.service"))
(expect.toExist (machine.file "/run/example/ready"))
```

Assertions retry observations until the configured timeout. Actions such as
keyboard input, service restarts, and mutating requests execute once.

## Steps

`test.step` groups actions under a diagnostic name in the test log:

```nix
(test.step "service becomes usable" [
  (expect.toBeActive (machine.service "example.service"))
  (expect.toHaveStatus 200 (machine.http.get "http://localhost/health"))
])
```

Steps may contain other steps.

## Configuration

Set suite-wide defaults with `test.configure`:

```nix
test.configure = {
  timeout = 30;
  terminal = {
    columns = 100;
    rows = 30;
  };
};
```

The default assertion timeout is 15 seconds. Standalone terminal tests default
to 140 columns by 42 rows.

## Separate Test Files

Colocate tests with the code they cover using the `*.test.nix` suffix:

```text
src/
├── terminal.nix
└── terminal.test.nix
```

A test file is a per-system module:

```nix
{ pkgs, ... }:
{
  test."shows a greeting" = { terminal, expect }: [
    (terminal.open pkgs.hello)
    (expect.toBeVisible (terminal.getByText "Hello"))
  ];
}
```

Import it from `perSystem`:

```nix
perSystem = { ... }: {
  imports = [ ./src/terminal.test.nix ];
};
```
