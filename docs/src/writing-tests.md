# Writing Tests

Tests are named attributes whose values are callbacks. A callback receives the
fixtures it requests and returns an ordered list of actions.

```nix
test."saves the document" = { terminal, filesystem }: [
  (filesystem.writeFile "document.txt" "draft\n")
  (terminal.open "${editor} ${filesystem.root}/document.txt")
  (expect (terminal.getByText "draft")).toBeVisible
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
  (expect (terminal.getByText "ready")).toBeVisible
]
```

## Fixtures

Fixtures describe the boundary under test. Request only what the test uses:

```nix
{ terminal, filesystem }:
```

Use `terminal` for local command-line applications and `machine` or `machines`
for NixOS VMs. Semantic fixtures such as `service`, `filesystem`, `network`,
`http`, and `user` build on the machine backend. See
[Fixtures and Assertions](fixtures.md).

## Locators And Assertions

Locators describe observable state; matchers assert against it:

```nix
(expect (terminal.getByText "ready")).toBeVisible
(expect (machine.service "example.service")).toBeActive
(expect (machine.file "/run/example/ready")).toExist
```

Assertions retry observations until the configured timeout. Actions such as
keyboard input, service restarts, and mutating requests execute once.

## Steps

`test.step` groups actions under a diagnostic name in the test log:

```nix
(test.step "service becomes usable" [
  (expect (machine.service "example.service")).toBeActive
  ((expect (machine.http.get "http://localhost/health")).toHaveStatus 200)
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
{ pkgs, expect, ... }:
{
  test."shows a greeting" = { terminal }: [
    (terminal.open pkgs.hello)
    (expect (terminal.getByText "Hello")).toBeVisible
  ];
}
```

Import it from `perSystem`:

```nix
perSystem = { ... }: {
  imports = [ ./src/terminal.test.nix ];
};
```
