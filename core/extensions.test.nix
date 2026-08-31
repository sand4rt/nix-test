{ inputs, ... }:
{
  perSystem = { pkgs, expect, ... }: {
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
          (expect (inputs.self.lib.mkLocator {
            type = "terminalText";
            inherit (target) text;
          })).toBeVisible;
      };
    };

    test."custom fixtures and matchers" = { greeting }:
      greeting.setup ++ [ (expect greeting.custom).toBePresent ];
  };
}
