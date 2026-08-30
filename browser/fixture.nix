{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
let
  browserExpression = name: ''browsers[${builtins.toJSON name}]'';
  find = target: ''find_element(${browserExpression target.node}, ${builtins.toJSON target.strategy}, ${builtins.toJSON target.value})'';
  locator = node: strategy: value: description:
    let target = { type = "browserElement"; inherit node strategy value description; };
    in mkLocator (target // {
      toBeVisible = mkAction "browserAssertion" {
        inherit node description;
        code = ''WebDriverWait(${browserExpression node}, timeout).until(lambda _: ${find target}.is_displayed())'';
      };
    });
  action = target: operation: code: mkAction "browserAction" {
    inherit (target) node;
    inherit operation code;
  };
in
{
  testing.fixtures.browser = mkFixture (_fixtures: {
    configure = node: mkAction "browserConfigure" {
      node = node.name;
      code = ''
        from selenium import webdriver
        import json
        from selenium.webdriver.common.by import By
        from selenium.webdriver.firefox.options import Options
        from selenium.webdriver.support.ui import WebDriverWait

        def find_element(browser, strategy, value):
            if strategy == "role":
                role, name = value.split("\0", 1)
                query = f"//*[@role={json.dumps(role)} and (@aria-label={json.dumps(name)} or normalize-space(.)={json.dumps(name)})]"
                return browser.find_element(By.XPATH, query)
            return browser.find_element({
                "label": By.XPATH,
                "placeholder": By.CSS_SELECTOR,
                "text": By.XPATH,
                "title": By.CSS_SELECTOR,
            }[strategy], value)

        options = Options()
        options.add_argument("--headless")
        options.binary_location = ${builtins.toJSON (lib.getExe pkgs.firefox)}
        service = webdriver.FirefoxService(executable_path=${builtins.toJSON (lib.getExe pkgs.geckodriver)})
        browsers[${builtins.toJSON node.name}] = webdriver.Firefox(options=options, service=service)
      '';
    };
    open = node: url: mkAction "browserAction" {
      node = node.name;
      operation = "open";
      code = ''${browserExpression node.name}.get(${builtins.toJSON url})'';
    };
    getByRole = node: role: { name ? "" }:
      locator node.name "role" "${role}\u0000${name}" "${role} named ${name}";
    getByLabel = node: label:
      locator node.name "label" (
        ''//label[normalize-space(.)=${builtins.toJSON label}]//*[@id][1] | //*[@id=//label[normalize-space(.)=${builtins.toJSON label}]/@for]''
      ) "field labelled ${label}";
    getByPlaceholder = node: placeholder:
      locator node.name "placeholder" "[placeholder=${builtins.toJSON placeholder}]" "field with placeholder ${placeholder}";
    getByText = node: text:
      locator node.name "text" ''//*[normalize-space(.)=${builtins.toJSON text}]'' "text ${text}";
    getByTitle = node: title:
      locator node.name "title" "[title=${builtins.toJSON title}]" "element titled ${title}";
    click = target: action target "click" ''${find target}.click()'';
    fill = target: value: action target "fill" ''
      element = ${find target}
      element.clear()
      element.send_keys(${builtins.toJSON value})
    '';
    clear = target: action target "clear" ''${find target}.clear()'';
    press = target: keys: action target "press" ''${find target}.send_keys(${builtins.toJSON keys})'';
  });
}
