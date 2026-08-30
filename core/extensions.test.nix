{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    testing = {
      fixtures.greeting = inputs.self.lib.mkFixture ({ terminal, ... }: {
        setup = [ (terminal.open pkgs.hello) ];
        locator = terminal.getByText "Hello";
      });

      locators.greeting.custom = inputs.self.lib.mkLocator {
        type = "greetingText";
        text = "Hello";
      };

      matchers.toBePresent = inputs.self.lib.mkMatcher {
        accepts = [ "greetingText" ];
        run = { expect, ... }: target:
          expect.toBeVisible (inputs.self.lib.mkLocator {
            type = "terminalText";
            inherit (target) text;
          });
      };
    };

    test."custom fixtures and matchers" =
      { greeting, expect }:
      greeting.setup ++ [ (expect.toBePresent greeting.custom) ];
  };
}
