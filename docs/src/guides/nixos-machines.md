# NixOS Machines

Use `machine` when behavior depends on a NixOS configuration. Every machine test
starts with `machine.configure`, which selects the NixOS VM backend.

```nix
test."service becomes healthy" = { machine, expect }: [
  (machine.configure {
    modules = [
      self.nixosModules.default
      { services.example.enable = true; }
    ];
  })

  (expect.toBeActive (machine.service "example.service"))
  (expect.toExist (machine.file "/run/example/ready"))
  (expect.toHaveStatus 200 (machine.http.get "http://localhost/health"))
];
```

## Semantic System State

Use semantic fixtures for services, filesystems, endpoints, HTTP, users, and
containers. Their matchers retry until the expected state appears.

```nix
let app = machine.service "example.service"; in [
  (expect.toBeActive app)
  (expect.toHaveLog app "configuration loaded")
  (expect.toBeOwnedBy (machine.file "/var/lib/example") "example")
  (expect.toBeReachable (machine.endpoint.tcp 8080))
]
```

## Terminal Interaction In A VM

`machine` also implements the terminal interface:

```nix
[
  (machine.open "example-tui")
  (machine.press "start<enter>")
  (expect.toBeVisible (machine.getByText "running"))
]
```

For exploratory access, guest shells, SSH, and forwarded ports, see
[Debugging](../debugging.md).
