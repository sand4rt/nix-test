# Extending Nix Test

Plugins add project-specific fixtures, locators, and matchers through mergeable
flake-parts options.

## Custom Fixture

```nix
testing.fixtures.app = inputs.tests.lib.mkFixture (_fixtures: {
  status = name:
    inputs.tests.lib.mkLocator {
      type = "appStatus";
      status = name;
    };
});
```

The factory receives the complete fixture set. Its return value is injected as
`app` into test callbacks.

## Custom Matcher

```nix
testing.matchers.toBeReady = inputs.tests.lib.mkMatcher {
  accepts = [ "appStatus" ];
  run = { expect, ... }: target:
    (expect (inputs.tests.lib.mkLocator {
      type = "terminalText";
      text = target.status;
    })).toBeVisible;
};
```

Constructors validate value shape and matcher compatibility during Nix
evaluation. Prefer composing custom matchers from existing runtime-backed
locators and matchers.

## Reusable Plugin

Put fixture, locator, and matcher declarations in a flake-parts module and
import it beside Nix Test:

```nix
imports = [
  inputs.tests.flakeModules.default
  ./testing/plugin.nix
];
```

Tests can then request the custom fixture and matcher without importing the
plugin themselves. See the [Core API](../reference/core.md) for constructor
signatures.
