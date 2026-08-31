{ mkAction, mkMatcher, ... }:
/**
  @doc assertions.desktop
  ## Desktop

  ```nix
  (expect target).toBeVisible
  ```

  Accepts desktop window and desktop text locators.
*/
let nodeExpression = name: ''machines[${builtins.toJSON name}]'';
in
{
  testing.matchers.toBeVisibleOnDesktop = mkMatcher {
    accepts = [ "desktopWindow" "desktopText" ];
    run = _fixtures: target: mkAction "desktopAssertion" {
      inherit (target) node description;
      code = if target.type == "desktopWindow" then
        ''${nodeExpression target.node}.wait_for_window(${builtins.toJSON target.title}, timeout=timeout)''
      else
        ''${nodeExpression target.node}.wait_for_text(${builtins.toJSON target.text}, timeout=timeout)'';
    };
  };
}
