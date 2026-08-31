{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.browser
  ## `browser`

  Browser actions run through Firefox and Selenium on the machine backend.
  Access a bound browser through `machine.browser`.

  ```nix
  machine.browser.start
  machine.browser.open url
  machine.browser.getByRole role { name ? ""; }
  machine.browser.getByLabel label
  machine.browser.getByPlaceholder placeholder
  machine.browser.getByText text
  machine.browser.getByTitle title
  ```

  Locator methods return browser element locators. Action methods execute once.
*/
let
  browserExpression = name: ''browsers[${builtins.toJSON name}]'';
  find = target: ''find_element(${browserExpression target.node}, ${builtins.toJSON target.strategy}, ${builtins.toJSON target.value})'';
  locator = node: strategy: value: description:
    let target = { type = "browserElement"; inherit node strategy value description; };
    in mkLocator (target // {
      click = action target "click" ''${find target}.click()'';
      fill = input: action target "fill" ''
        element = ${find target}
        element.clear()
        element.send_keys(${builtins.toJSON input})
      '';
      clear = action target "clear" ''${find target}.clear()'';
      press = keys: action target "press" ''${find target}.send_keys(${builtins.toJSON keys})'';
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
    on = node: {
      _kind = "locator";
      type = "browserPage";
      node = node.name;
      description = "browser on ${node.name}";
      start = mkAction "browserConfigure" {
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
                native_roles = {
                    "button": "self::button or self::input[@type='button' or @type='submit' or @type='reset']",
                    "link": "self::a[@href]",
                    "textbox": "self::textarea or self::input[not(@type) or @type='text' or @type='email' or @type='search' or @type='tel' or @type='url']",
                }
                role_query = f"@role={json.dumps(role)}"
                if role in native_roles:
                    role_query = f"({role_query} or {native_roles[role]})"
                name_query = f"(@aria-label={json.dumps(name)} or normalize-space(.)={json.dumps(name)} or @value={json.dumps(name)})"
                query = f"//*[{role_query} and {name_query}]"
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
      open = url: mkAction "browserAction" {
      node = node.name;
      operation = "open";
      code = ''${browserExpression node.name}.get(${builtins.toJSON url})'';
      };
      getByRole = role: { name ? "" }:
      locator node.name "role" "${role}\u0000${name}" "${role} named ${name}";
      getByLabel = label:
      locator node.name "label" (
        ''//label[normalize-space(.)=${builtins.toJSON label}]//*[@id][1] | //*[@id=//label[normalize-space(.)=${builtins.toJSON label}]/@for]''
      ) "field labelled ${label}";
      getByPlaceholder = placeholder:
      locator node.name "placeholder" "[placeholder=${builtins.toJSON placeholder}]" "field with placeholder ${placeholder}";
      getByText = text:
      locator node.name "text" ''//*[normalize-space(.)=${builtins.toJSON text}]'' "text ${text}";
      getByTitle = title:
      locator node.name "title" "[title=${builtins.toJSON title}]" "element titled ${title}";
    };
  });
}
