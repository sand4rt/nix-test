# Extending Nix Test

Projects can add domain-specific fixtures and matchers through the mergeable
`testing.fixtures` and `testing.matchers` options.

This example adds:

- `app.status name`, a locator for an application's systemd service
- `toBeOperational`, a matcher that checks that service

## Define The Extension

Create `testing/app.nix`:

```nix
{ inputs, ... }:
{
  perSystem = { ... }: {
    testing.fixtures.app = inputs.nix-test.lib.mkFixture (
      { machine, ... }:
      {
        status = name:
          inputs.nix-test.lib.mkLocator {
            type = "appStatus";
            node = machine.name;
            service = "${name}.service";
            description = "application ${name}";
          };
      }
    );

    testing.matchers.toBeOperational = inputs.nix-test.lib.mkMatcher {
      accepts = [ "appStatus" ];
      run = { machine, expect, ... }: target:
        (expect (machine.service target.service)).toBeActive;
    };
  };
}
```

`mkFixture` receives the complete runtime fixture set. Its returned value is
available under the configured name, so this factory creates the `app` fixture.

`mkLocator` gives the target a distinct `type`. The matcher's `accepts` list
limits `toBeOperational` to that type, and its `run` function composes the built-in
service locator and matcher.

## Import The Extension

Import the extension beside Nix Test in `flake.nix`:

```nix
imports = [
  inputs.nix-test.flakeModules.default
  ./testing/app.nix
];
```

## Use It In A Test

Create `tests/app.test.nix`:

```nix
{ expect, ... }:
{
  test."starts the API" = { app, machine }: [
    (machine.configure {
      modules = [
        {
          systemd.services.api = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "touch /run/api-ready";
          };
        }
      ];
    })

    (expect (app.status "api")).toBeOperational
  ];
}
```

`expect` is imported at module scope. `app` and `machine` are runtime fixtures,
so the test requests them in its callback.

Invalid combinations fail during Nix evaluation. For example,
`(expect (machine.file "/run/api-ready")).toBeOperational` is rejected because a
file locator is not an `appStatus` target.

See the [Core API](../reference/core.md) for the exact `mkFixture`, `mkLocator`,
and `mkMatcher` signatures.
