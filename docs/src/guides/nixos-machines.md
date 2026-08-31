# NixOS Machines

Use `machine` when behavior depends on a NixOS VM. Machine actions automatically
create an empty default VM. Add `machine.configure` only when the test needs
NixOS modules.

```nix
test."service becomes healthy" = { machine }: [
  (machine.configure {
    modules = [
      self.nixosModules.default
      { services.example.enable = true; }
    ];
  })

  (expect (machine.service "example.service")).toBeActive
  (expect (machine.file "/run/example/ready")).toExist
  ((expect (machine.http.get "http://localhost/health")).toHaveStatus 200)
];
```

## Semantic System State

Use semantic fixtures for services, filesystems, endpoints, HTTP, users, and
containers. Their matchers retry until the expected state appears.

```nix
[
  (expect (machine.service "example.service")).toBeActive
  ((expect (machine.service "example.service").logs).toContain "configuration loaded")
  ((expect (machine.file "/var/lib/example")).toBeOwnedBy "example")
  (expect (machine.endpoint.tcp 8080)).toBeReachable
]
```

## Terminal Interaction In A VM

`machine` also implements the terminal interface:

```nix
[
  (machine.open "example-tui")
  (machine.press "start<enter>")
  (expect (machine.getByText "running")).toBeVisible
]
```

For exploratory access, guest shells, SSH, and forwarded ports, see
[Debugging](../debugging.md).
