{ mkAction, mkMatcher, ... }:
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
    toHaveLocation = fixtures: node: expected: mkAction "browserAssertion" {
      node = node.name;
      description = "browser location ${expected}";
      code = ''WebDriverWait(${browserExpression node.name}, timeout).until(lambda _: ${browserExpression node.name}.current_url.endswith(${builtins.toJSON expected}))'';
    };
    toHaveTitle = fixtures: node: expected: mkAction "browserAssertion" {
      node = node.name;
      description = "browser title ${expected}";
      code = ''WebDriverWait(${browserExpression node.name}, timeout).until(lambda _: ${browserExpression node.name}.title == ${builtins.toJSON expected})'';
    };
  };
}
