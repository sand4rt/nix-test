# Getting Started

Nix Tests turns each named test into a flake check. Tests are ordinary attribute
sets, so they can be declared inline, imported from files, and merged with `//`.

## Flake-parts

Add Nix Tests as an input and import its module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    tests = {
      url = "github:sand4rt/nix-testing";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.tests.flakeModules.default ];
      systems = [ "aarch64-linux" "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:
        {
          test."shows greeting" = { terminal, expect }: [
            (terminal.open pkgs.hello)
            (expect.toBeVisible (terminal.getByText "Hello"))
          ];
        };
    };
}
```

The attribute name is both the test name and its check name. There is no test
constructor to import.

## Configuration

Use `test.configure` to set defaults for every test in the current `perSystem`:

```nix
test.configure = {
  timeout = 30;
  terminal = {
    columns = 80;
    rows = 24;
  };
};
```

All fields are optional. The defaults are a 15-second assertion timeout and a
terminal measuring 140 columns by 42 rows.

## Plain Flakes

Without flake-parts, pass the test attribute set directly to `lib.mkTests`:

```nix
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs { inherit system; };
in
{
  checks.${system} = inputs.tests.lib.mkTests {
    inherit pkgs;
    test.configure.timeout = 30;
    test."shows greeting" = { terminal, expect }: [
      (terminal.open pkgs.hello)
      (expect.toBeVisible (terminal.getByText "Hello"))
    ];
  };
}
```

The optional `fixtures` and `matchers` arguments use the same format as the
flake-parts plugin options.

## Package Outputs

Use a package output directly so the test executes the exact store path built by
the flake:

```nix
perSystem =
  { config, pkgs, ... }:
  {
    packages.default = pkgs.callPackage ./package.nix { };

    test."prints its version" = { terminal, expect }: [
      (terminal.open "${pkgs.lib.getExe config.packages.default} --version")
      (expect.toBeVisible (terminal.getByText "my-app"))
    ];
  };
```

When no arguments are needed, pass the package itself:

```nix
terminal.open config.packages.default
```

`terminal.open` resolves the package's `meta.mainProgram` with `lib.getExe`.
Use a command string when arguments are needed, as in the version example
above.

Use `lib.getExe'` when the binary name differs from the package's main program:

```nix
terminal.open (pkgs.lib.getExe' package "program-name")
```

## Workspace Files

Use `workspace` for mutable files created specifically for a test:

```nix
test."reads a config file" =
  { terminal, workspace, expect }:
  [
    (workspace.writeFile "config.toml" ''
      greeting = "Hello"
    '')
    (terminal.open "${pkgs.lib.getExe my-package} --config ${workspace.path}/config.toml")
    (expect.toBeVisible (terminal.getByText "Hello"))
  ];
```

`workspace.path` is replaced by the isolated runtime directory. Package
dependencies should use `terminal.open package` or explicit store paths, not
`PATH`.

## NixOS Modules

Pass NixOS modules to `machine.configure`. Commands run on the resulting machine:

```nix
test."starts the service" = { machine, expect }: [
  (machine.configure {
    modules = [
      self.nixosModules.default
      { services.my-service.enable = true; }
    ];
  })

  (expect.toEventuallySucceed (machine.command "systemctl is-active my-service.service"))
];
```

Use machine tests for services, users, permissions, networking, and interactions
between NixOS modules.

## Home Manager Modules

Home Manager modules are tested through Home Manager's NixOS integration. Add
Home Manager to the consumer flake:

```nix
inputs.home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import its NixOS module and configure a test user:

```nix
test."activates the user configuration" = { machine, expect }: [
  (machine.configure {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      {
        users.users.test = {
          isNormalUser = true;
          home = "/home/test";
        };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.test = {
          imports = [ self.homeModules.default ];
          home.stateVersion = "25.05";
        };
      }
    ];
  })

  (machine.command "test -e /home/test/.config/my-app/config.toml")
];
```

Choose `home.stateVersion` according to the project being tested.

## Separate Test Files

Colocate tests with the code they cover using a `*.test.nix` suffix:

```text
src/
├── terminal.nix
└── terminal.test.nix
```

The test file is a per-system module:

```nix
# src/terminal.test.nix
{ pkgs, ... }:
{
    test."shows greeting" = { terminal, expect }: [
    (terminal.open pkgs.hello)
    (expect.toBeVisible (terminal.getByText "Hello"))
  ];
}
```

Import one file:

```nix
perSystem = { ... }: {
  imports = [ ./src/terminal.test.nix ];
};
```

Import each colocated test module:

```nix
perSystem = { ... }: {
  imports = [
    ./src/terminal.test.nix
    ./modules/service.test.nix
  ];
};
```

## Plugins

Plugins are flake-parts modules that declare custom fixture and matcher options:

```nix
# src/plugin.nix
{ ... }:
{
  perSystem = { pkgs, ... }: {
    testing.fixtures.app = inputs.tests.lib.mkFixture (_fixtures: {
      name = "app";
    });

    testing.locators.app.getByStatus = status:
      inputs.tests.lib.mkLocator {
        type = "appStatus";
        inherit status;
      };

    testing.matchers.toBeReady = inputs.tests.lib.mkMatcher {
      accepts = [ "appStatus" ];
      run = _fixtures: target:
        inputs.tests.lib.mkAction "assertAppStatus" {
          inherit (target) name;
        };
    };
  };
}
```

Import the plugin once beside the framework module:

```nix
imports = [
  inputs.tests.flakeModules.default
  ./src/plugin.nix
];
```

Every test can then request `app` and use `expect.toBeReady` without importing
the plugin itself. See [Fixtures](fixtures.md#plugins) for complete examples.

## Running Tests

Run every check for the current system:

```sh
nix flake check
```

Run one named test:

```sh
nix build '.#checks.x86_64-linux."shows greeting"' --no-link -L
```

Replace the system segment with one enabled by the consumer flake. `-L` streams
the test log.
