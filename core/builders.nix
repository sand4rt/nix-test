{
  /**
    @doc lib.mkFixture
    ## `lib.mkFixture`

    ```nix
    inputs.tests.lib.mkFixture ({ terminal, filesystem, ... }: {
      open = file: [
        (filesystem.writeFile file "")
        (terminal.open file)
      ];
    })
    ```

    Registers a fixture factory. The factory receives the recursive fixture set
    and returns the value exposed to test callbacks.
  */
  mkFixture =
    factory:
    assert builtins.isFunction factory;
    {
      _kind = "fixture";
      inherit factory;
    };

  mkAction =
    type: payload:
    payload
    // {
      _kind = "action";
      inherit type;
    };

  /**
    @doc lib.mkLocator
    ## `lib.mkLocator`

    ```nix
    inputs.tests.lib.mkLocator {
      type = "appStatus";
      inherit name;
    }
    ```

    Creates a typed locator for custom fixtures and matchers. The `type` identifies
    compatible matchers; all other attributes hold locator-specific data.
  */
  mkLocator =
    locator:
    assert builtins.isAttrs locator;
    assert builtins.isString (locator.type or null);
    locator // { _kind = "locator"; };

  /**
    @doc lib.mkMatcher
    ## `lib.mkMatcher`

    ```nix
    inputs.tests.lib.mkMatcher {
      accepts = [ "appStatus" ];
      run = { expect, ... }: target:
          (expect (inputs.tests.lib.mkLocator {
            type = "terminalText";
            text = target.status;
          })).toBeVisible;
    }
    ```

    Creates a fixture-aware matcher factory. `accepts` lists valid target types;
    omit it for a matcher that accepts any tagged action or locator.
    Invalid targets fail during Nix evaluation before a runner is built. Compose
    matchers from runtime-backed locators and matchers unless a runner explicitly
    supports the custom action type.
  */
  mkMatcher =
    {
      run,
      accepts ? null,
    }:
    fixtures: target:
    assert builtins.isAttrs target;
    assert builtins.elem (target._kind or null) [
      "action"
      "locator"
    ];
    assert accepts == null || builtins.elem target.type accepts;
    run fixtures target;
}
