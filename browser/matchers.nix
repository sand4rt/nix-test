{ mkAction, mkMatcher, ... }:
/**
  @doc assertions.browser
  ## Browser

  ```nix
  (expect element).toBeVisible
  (expect element).toBeEnabled
  (expect element).toHaveValue expected
  (expect machine.browser).toHaveLocation expectedSuffix
  (expect machine.browser).toHaveTitle expectedTitle
  ```

  Browser assertions retry through Selenium until timeout.
*/
let
  browserExpression = name: ''browsers[${builtins.toJSON name}]'';
  find = target: ''find_element(${browserExpression target.node}, ${builtins.toJSON target.strategy}, ${builtins.toJSON target.value})'';
in
{
  testing.matchers = {
    toBeVisibleInBrowser = mkMatcher {
      accepts = [ "browserElement" ];
      run = _fixtures: target: mkAction "browserAssertion" {
        inherit (target) node description;
        code = ''WebDriverWait(${browserExpression target.node}, timeout).until(lambda _: ${find target}.is_displayed())'';
      };
    };
    toBeEnabled = mkMatcher {
      accepts = [ "browserElement" ];
      run = _fixtures: target: mkAction "browserAssertion" {
        inherit (target) node description;
        code = ''WebDriverWait(${browserExpression target.node}, timeout).until(lambda _: ${find target}.is_enabled())'';
      };
    };
    toHaveValue = fixtures: target: expected: mkAction "browserAssertion" {
      inherit (target) node description;
      code = ''WebDriverWait(${browserExpression target.node}, timeout).until(lambda _: ${find target}.get_attribute("value") == ${builtins.toJSON expected})'';
    };
    toHaveLocation = fixtures: target: expected: mkAction "browserAssertion" {
      node = target.node;
      description = "browser location ${expected}";
      code = ''WebDriverWait(${browserExpression target.node}, timeout).until(lambda _: ${browserExpression target.node}.current_url.endswith(${builtins.toJSON expected}))'';
    };
    toHaveTitle = fixtures: target: expected: mkAction "browserAssertion" {
      node = target.node;
      description = "browser title ${expected}";
      code = ''WebDriverWait(${browserExpression target.node}, timeout).until(lambda _: ${browserExpression target.node}.title == ${builtins.toJSON expected})'';
    };
  };
}
