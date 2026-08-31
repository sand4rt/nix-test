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

  Browser actions run through Playwright on the machine backend.
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
  python = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.playwright ]);
  run = node: code:
    let
      script = ''
        from playwright.sync_api import expect, sync_playwright
        import sys

        timeout_ms = int(sys.argv[1]) * 1000
        playwright_instance = sync_playwright().start()
        browser = playwright_instance.chromium.connect_over_cdp("http://127.0.0.1:9222")
        page = browser.contexts[0].pages[0]
        try:
        ${lib.concatMapStringsSep "\n" (line: "    ${line}") (lib.splitString "\n" code)}
        finally:
            playwright_instance.stop()
      '';
      command = "${python}/bin/python -c ${lib.escapeShellArg script}";
    in ''${nodeExpression node}.succeed(${builtins.toJSON command} + " " + str(timeout))'';
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  find = target:
    if target.strategy == "role" then
      let roleAndName = lib.splitString "\u0000" target.value;
      in ''page.get_by_role(${builtins.toJSON (builtins.head roleAndName)}, name=${builtins.toJSON (builtins.elemAt roleAndName 1)})''
    else
      ''page.${
        {
          label = "get_by_label";
          placeholder = "get_by_placeholder";
          text = "get_by_text";
          title = "get_by_title";
        }.${target.strategy}
      }(${builtins.toJSON target.value})'';
  locator = node: strategy: value: description:
    let target = { type = "browserElement"; inherit node strategy value description; };
    in mkLocator (target // {
      click = action target "click" ''${find target}.click(timeout=timeout_ms)'';
      fill = input: action target "fill" ''${find target}.fill(${builtins.toJSON input}, timeout=timeout_ms)'';
      clear = action target "clear" ''${find target}.clear(timeout=timeout_ms)'';
      press = keys: action target "press" ''${find target}.press(${builtins.toJSON keys}, timeout=timeout_ms)'';
      toBeVisible = mkAction "browserAssertion" {
        inherit node description;
        code = run node ''${find target}.wait_for(state="visible", timeout=timeout_ms)'';
      };
    });
  action = target: operation: code: mkAction "browserAction" {
    inherit (target) node;
    inherit operation;
    code = run target.node code;
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
        ${nodeExpression node.name}.succeed("mkdir -p /tmp/nix-test-browser")
        ${nodeExpression node.name}.succeed("HOME=/tmp/nix-test-browser ${lib.getExe pkgs.chromium} --headless --no-sandbox --disable-dev-shm-usage --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 --user-data-dir=/tmp/nix-test-browser/profile about:blank >/tmp/nix-test-browser/chromium.log 2>&1 &")
        ${nodeExpression node.name}.wait_until_succeeds("curl --fail --silent http://127.0.0.1:9222/json/version", timeout=timeout)
      '';
      };
      open = url: mkAction "browserAction" {
      node = node.name;
      operation = "open";
      code = run node.name ''page.goto(${builtins.toJSON url}, timeout=timeout_ms)'';
      };
      getByRole = role: { name ? "" }:
      locator node.name "role" "${role}\u0000${name}" "${role} named ${name}";
      getByLabel = label:
      locator node.name "label" label "field labelled ${label}";
      getByPlaceholder = placeholder:
      locator node.name "placeholder" placeholder "field with placeholder ${placeholder}";
      getByText = text:
      locator node.name "text" text "text ${text}";
      getByTitle = title:
      locator node.name "title" title "element titled ${title}";
    };
  });
}
