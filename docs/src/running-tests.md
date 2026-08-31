# Running Tests

Every named test is exposed as a check for its system.

## Run One Test

```sh
nix build '.#checks.x86_64-linux."shows greeting"' --no-link -L
```

`--no-link` avoids creating a result symlink. `-L` streams the test log.

## Run All Tests

```sh
nix flake check
```

Use `nix flake show` to list generated check names.

## Without Flake-parts

Pass tests directly to `lib.mkTests`:

```nix
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in {
  checks.${system} = inputs.tests.lib.mkTests {
    inherit pkgs;
    test = (import ./tests/hello.test.nix { inherit pkgs; }).test;
  };
}
```

`fixtures`, `locators`, and `matchers` accept the same plugin values as their
flake-parts options.

## Without Flakes

With Nix Test available at a local path:

```nix
# tests.nix
{ pkgs ? import <nixpkgs> { }, nix-test ? ./vendor/nix-test }:
(import "${nix-test}/core/mk-tests.nix") {
  inherit pkgs;
  test = (import ./tests/hello.test.nix { inherit pkgs; }).test;
}
```

Run one test with:

```sh
nix-build tests.nix -A 'shows a greeting'
```

## Interactive Machine Tests

Machine checks expose the standard NixOS interactive driver:

```sh
nix build \
  '.#checks.x86_64-linux."service starts".driverInteractive' \
  -o result-driver
./result-driver/bin/nixos-test-driver
```

Continue with [Debugging](debugging.md) for VM shells, SSH, port forwarding, and
persistent machine state.
