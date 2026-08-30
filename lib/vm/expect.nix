/** @doc expect.vm
## `expect` (VM command)

```nix
expect command
```

Creates an assertion for `command` on the NixOS test machine.

### `toSucceed`

Runs the command once and requires a successful exit status.

```nix
(expect "systemctl --user is-active example.service").toSucceed
```

### `toEventuallySucceed`

Retries the command using the NixOS test driver until it succeeds or times out.

```nix
(expect "test -e /run/example-ready").toEventuallySucceed
```

### `toFail`

Runs the command once and requires a non-zero exit status.

```nix
(expect "pgrep forbidden-process").toFail
```
*/
command: {
  toSucceed = {
      type = "vmCommand";
    code = ''machine.succeed(f"{user} " + ${builtins.toJSON command})'';
  };

  toEventuallySucceed = {
      type = "vmCommand";
    code = ''machine.wait_until_succeeds(f"{user} " + ${builtins.toJSON command})'';
  };

  toFail = {
      type = "vmCommand";
    code = ''machine.fail(${builtins.toJSON command})'';
  };
}
