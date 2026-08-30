{ lib, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      builders = import ./core/builders.nix;
    in
    {
      config._module.args = builders // {
        test = import ./step/fixture.nix builders;
      };
      /**
        @doc test
        ## `test`

        ```nix
        test."shows greeting" = { terminal, expect }: [
          (terminal.open pkgs.hello)
          (expect.toBeVisible (terminal.getByText "Hello"))
        ];
        ```

        A mergeable attribute set of integration-test callbacks. Attribute names
        become check names. Each callback receives the resolved fixture set and
        returns an ordered list of actions. `test.configure` is reserved for
        suite-wide configuration.
      */
      options.test = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
        description = "Integration tests exposed as flake checks.";
      };

      /**
        @doc test.configure
        ## `test.configure`

        ```nix
        test.configure = {
          timeout = 30;
          terminal = {
            columns = 80;
            rows = 24;
          };
        };
        ```

        Configures every test declared in the current `perSystem` scope. `timeout`
        controls standalone terminal assertion retries and defaults to 15 seconds.
        Standalone terminal dimensions default to 140 columns by 42 rows.
      */

      /**
        @doc testing.fixtures
        ## `testing.fixtures`

        ```nix
        testing.fixtures.app = inputs.tests.lib.mkFixture ({ terminal, workspace, ... }: {
          open = file: [
            (workspace.writeFile file "")
            (terminal.open file)
          ];
        });
        ```

        A mergeable attribute set of fixtures created with `lib.mkFixture`. Each
        factory receives the complete fixture set and returns the value injected
        under its attribute name. Built-in fixture names cannot be replaced.
      */
      options.testing.fixtures = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
        description = "Custom integration-test fixture factories.";
      };

      /**
        @doc testing.locators
        ## `testing.locators`

        ```nix
        testing.locators.app.getByStatus = status: mkLocator {
          type = "appStatus";
          inherit status;
        };
        ```

        Locators grouped by their owning fixture. Locator modules can be imported
        directly and receive `mkLocator` as a per-system module argument.
      */
      options.testing.locators = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
        default = { };
        description = "Custom locators grouped by fixture name.";
      };

      /**
        @doc testing.matchers
        ## `testing.matchers`

        ```nix
        testing.matchers.toBeReady = inputs.tests.lib.mkMatcher {
          accepts = [ "appStatus" ];
          run = _fixtures: target:
            inputs.tests.lib.mkAction "assertAppStatus" {
              inherit (target) name;
            };
        };
        ```

        A mergeable attribute set of custom matcher factories. Each factory
        receives the complete fixture set and returns a matcher function exposed
        on `expect` under its attribute name. Use `lib.mkMatcher` to validate
        targets. Built-in matcher names cannot be replaced.
      */
      options.testing.matchers = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
        description = "Custom integration-test matcher factories.";
      };

      config.checks = import ./core/mk-tests.nix {
        inherit pkgs;
        inherit (config) test;
        inherit (config.testing) fixtures locators matchers;
      };
    };
}
