# ❄️ Nix test

## Getting Started

This example boots a NixOS VM, starts a real IRC server, opens Irssi in a
terminal, and sends a message.

### 1. Choose Your Setup

<details open>
<summary><strong>flake-parts</strong></summary>

Add Nix Test to `flake.nix` and import the test module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    tests = {
      url = "github:sand4rt/nix-test";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.tests.flakeModules.default ];
      systems = [ "x86_64-linux" ];

      perSystem = { ... }: {
        imports = [ ./tests/chat.test.nix ];
      };
    };
}
```

</details>

<details>
<summary><strong>flakes without flake-parts</strong></summary>

Add Nix Test to `flake.nix` and pass the imported tests to `lib.mkTests`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tests.url = "github:sand4rt/nix-test";
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      checks.${system} = inputs.tests.lib.mkTests {
        inherit pkgs;
        inherit (import ./tests/chat.test.nix { inherit pkgs; }) test;
      };
    };
}
```

</details>

<details>
<summary><strong>Nix without flakes</strong></summary>

Create `tests.nix`. This example expects Nix Test at `./vendor/nix-test`:

```nix
{ pkgs ? import <nixpkgs> { }, nix-test ? ./vendor/nix-test }:
(import "${nix-test}/core/mk-tests.nix") {
  inherit pkgs;
  inherit (import ./tests/chat.test.nix { inherit pkgs; }) test;
}
```

</details>

### 2. Write The Test

Create `tests/chat.test.nix`:

```nix
{ pkgs, ... }:
{
  test."sends a chat message" = { machine, expect }: [
    (machine.configure {
      modules = [{
        services.ngircd = {
          enable = true;
          config = ''
            [Global]
            Name = irc.example.test
            Info = Nix Test IRC
            AdminInfo1 = Nix Test
            AdminInfo2 = Local test server
            AdminEMail = admin@example.test
            Listen = 127.0.0.1
            MotdPhrase = Welcome to Nix Test IRC
            Ports = 6667

            [Options]
            PAM = no

            [Channel]
            Name = #nix-test
          '';
        };
        environment.systemPackages = [ pkgs.irssi ];
      }];
    })

    (expect.toBeActive (machine.service "ngircd.service"))
    (machine.open "irssi --connect localhost --nick alice")
    (expect.toBeVisible (machine.getByText "Welcome to Nix Test IRC"))
    (machine.press "/join #nix-test<enter>")
    (expect.toBeVisible (machine.getByText "#nix-test"))
    (machine.press "Hello from Nix!<enter>")
    (expect.toBeVisible (machine.getByText "Hello from Nix!"))
  ];
}
```

### 3. Run It

```sh
nix build '.#checks.x86_64-linux."sends a chat message"' --no-link -L
```

Without flakes, run:

```sh
nix-build tests.nix -A 'sends a chat message'
```

Use your system name instead of `x86_64-linux` when necessary. Flake users can
run every test with `nix flake check`.

## Documentation

[Getting started](https://sand4rt.github.io/nix-test/getting-started.html) ·
[Fixtures and matchers](https://sand4rt.github.io/nix-test/fixtures.html) ·
[API reference](https://sand4rt.github.io/nix-test/reference/core.html)
