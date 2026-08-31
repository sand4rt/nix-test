{
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.desktop
  ## `desktop`

  ```nix
  desktop.getByWindow machine title
  desktop.getByText machine text
  desktop.press machine keys
  desktop.type machine text
  desktop.screenshot machine name
  ```

  Desktop tests use the machine backend. Locators can be passed to visibility
  matchers; input and screenshot methods execute once.
*/
let nodeExpression = name: ''machines[${builtins.toJSON name}]'';
in
{
  testing.fixtures.desktop = mkFixture (_fixtures: {
    getByWindow = node: title:
      let description = "window ${title}";
      in mkLocator {
        type = "desktopWindow";
        node = node.name;
        inherit title description;
        toBeVisible = mkAction "desktopAssertion" {
          node = node.name;
          inherit description;
          code = ''${nodeExpression node.name}.wait_for_window(${builtins.toJSON title}, timeout=timeout)'';
        };
      };
    getByText = node: text:
      let description = "visible desktop text ${text}";
      in mkLocator {
        type = "desktopText";
        node = node.name;
        inherit text description;
        toBeVisible = mkAction "desktopAssertion" {
          node = node.name;
          inherit description;
          code = ''${nodeExpression node.name}.wait_for_text(${builtins.toJSON text}, timeout=timeout)'';
        };
      };
    press = node: keys: mkAction "desktopAction" {
      node = node.name;
      code = ''${nodeExpression node.name}.send_key(${builtins.toJSON keys})'';
    };
    type = node: text: mkAction "desktopAction" {
      node = node.name;
      code = ''${nodeExpression node.name}.send_chars(${builtins.toJSON text})'';
    };
    screenshot = node: name: mkAction "desktopAction" {
      node = node.name;
      code = ''${nodeExpression node.name}.screenshot(${builtins.toJSON name})'';
    };
  });
}
