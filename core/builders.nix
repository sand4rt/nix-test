{
  /**
    @doc lib.mkFixture
    ## `lib.mkFixture`

    ```nix
    inputs.tests.lib.mkFixture ({ terminal, workspace, ... }: {
      open = file: [
        (workspace.writeFile file "")
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

  /**
    @doc lib.mkAction
    ## `lib.mkAction`

    ```nix
    inputs.tests.lib.mkAction "appOpen" { inherit path; }
    ```

    Creates a typed test action for a runner to consume. Its payload must match
    the selected runner's requirements; terminal-runner actions must be JSON
    serializable.
  */
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
    @doc lib.mkTarget
    ## `lib.mkTarget`

    ```nix
    inputs.tests.lib.mkTarget "appStatus" { inherit name; }
    ```

    Creates a typed matcher target. Matchers use the target type to reject values
    from an incompatible fixture.
  */
  mkTarget =
    type: payload:
    payload
    // {
      _kind = "target";
      inherit type;
    };

  /**
    @doc lib.mkMatcher
    ## `lib.mkMatcher`

    ```nix
    inputs.tests.lib.mkMatcher {
      accepts = [ "appStatus" ];
      run = { expect, ... }: target:
        expect.toBeVisible (inputs.tests.lib.mkLocator {
          type = "terminalText";
          text = target.status;
        });
    }
    ```

    Creates a fixture-aware matcher factory. `accepts` lists valid target types;
    omit it for a matcher that accepts any tagged action, locator, or target.
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
      "target"
    ];
    assert accepts == null || builtins.elem target.type accepts;
    run fixtures target;
}
