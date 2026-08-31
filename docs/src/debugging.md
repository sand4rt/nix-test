# Debugging

Start with one focused check and stream its log:

```sh
nix build '.#checks.x86_64-linux."shows ready"' --no-link -L
```

Replace the system and test name with values from your flake. Use
`nix flake show` when you are unsure of the generated check name.

## Inspect Terminal State

Add `terminal.print` or `machine.print` after the interaction you want to
inspect:

```nix
[
  (terminal.press "<enter>")
  terminal.print
]
```

Text failures include the missing text and visible terminal state. Region
failures include both expected and observed cells. Read a completed build log
with:

```sh
nix log /nix/store/<test-derivation>
```

## Run A Machine Test Interactively

NixOS machine checks expose the standard interactive test driver. Build it
instead of the test result:

```sh
nix build \
  '.#checks.x86_64-linux."shows ready".driverInteractive' \
  -o result-driver
./result-driver/bin/nixos-test-driver
```

This opens a Python prompt without running the generated test automatically.
Start every configured VM:

```python
start_all()
```

For one default machine, use `machine`. Named machines are also available by
their generated Python variables. Useful driver commands include:

```python
machine.succeed("systemctl status example.service")
machine.execute("example-command")
machine.wait_for_unit("example.service")
machine.get_unit_info("example.service")
machine.journalctl("-u example.service")
```

Exit the Python prompt with `Ctrl-D`. The interactive driver is for exploration;
the declarative Nix Test case remains the source of truth.

## Open A Shell In A VM

After `start_all()`, attach directly to the guest shell:

```python
machine.shell_interact()
```

Use `Ctrl-D` to leave the guest shell and return to the Python driver prompt.
This is the fastest way to inspect files, run `systemctl`, or try a command in
the exact VM built for the test.

## SSH Into A Test VM

For access from a separate host terminal, generate a disposable key beside the
test configuration:

```sh
ssh-keygen -t ed25519 -N '' -f ./test-key
```

Keep `test-key` out of version control. Then enable OpenSSH and forward a local
host port to the guest:

```nix
(machine.configure {
  modules = [{
    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keyFiles = [ ./test-key.pub ];

    networking.firewall.allowedTCPPorts = [ 22 ];
    virtualisation.forwardPorts = [{
      from = "host";
      host.address = "127.0.0.1";
      host.port = 2222;
      guest.port = 22;
    }];
  }];
})
```

Start the interactive driver and VMs, then connect from another terminal:

```sh
ssh -i ./test-key -p 2222 root@127.0.0.1
```

Keep the private key out of the Nix store and repository. The public key may be
part of the test configuration. If port `2222` is already in use, choose another
host port. If the guest firewall is enabled, port `22` must be allowed.

## Forward A Service Port

The same `virtualisation.forwardPorts` option exposes an HTTP server, database,
or debugger to a host-side client:

```nix
virtualisation.forwardPorts = [{
  from = "host";
  host.address = "127.0.0.1";
  host.port = 8080;
  guest.port = 80;
}];
networking.firewall.allowedTCPPorts = [ 80 ];
```

Keep the interactive driver running, then open `http://127.0.0.1:8080` or use a
host-side client. Forwarding uses QEMU's user networking, supports IPv4, and
applies only while the VM is running.

Use different host ports for multiple named machines:

```nix
(machines.configure {
  server.modules = [{
    virtualisation.forwardPorts = [{
      from = "host";
      host.address = "127.0.0.1";
      host.port = 8081;
      guest.port = 80;
    }];
  }];
  client.modules = [ ];
})
```

## Preserve VM State

Interactive drivers reset VM disks by default. Pass `--keep-machine-state` when
you need changes to survive a driver restart:

```sh
./result-driver/bin/nixos-test-driver --keep-machine-state
```

Delete the state only when you intentionally want a clean VM. A normal Nix Test
build always starts from its declared configuration and does not rely on this
debug state.

## Common Failures

| Symptom | What to inspect |
| --- | --- |
| Text assertion times out | Add `terminal.print` or `machine.print` immediately before it |
| Service never becomes active | Use `machine.journalctl("-u name.service")` interactively |
| Command works manually but not in the test | Check its package is in the VM or use an explicit store path |
| Host cannot reach a forwarded port | Check the host port, guest firewall, service bind address, and that the driver is still running |
| SSH rejects the key | Check the public key module path, private key permissions, forwarded port, and target user |
| VM changes disappear | Start the driver with `--keep-machine-state`, or declare the change in `machine.configure` |

## Avoid Sleeps

Assertions already retry until the configured timeout. Synchronize on visible
or semantic state instead of adding delays:

```nix
(expect (terminal.getByText "ready")).toBeVisible
(expect (machine.service "example.service")).toBeActive
((expect (machine.http.get "http://example.test/health")).toHaveStatus 200)
```

Use `machine.command` for one-shot commands. Use `machine.run` when a command has
side effects and you need to assert against its saved result. Retrying a
side-effecting command can hide bugs or perform the operation more than once.

## Upstream Driver Reference

Nix Test's machine backend compiles actions to the standard NixOS test driver.
The upstream [NixOS Tests manual](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
documents the driver and VM model. Its dedicated [Running NixOS tests
interactively](https://nixos.org/manual/nixos/stable/#sec-running-nixos-tests-interactively)
section covers the underlying interactive workflow in more detail.
