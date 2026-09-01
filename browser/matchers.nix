{ lib, pkgs, mkAction, mkMatcher, ... }:
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

  Browser assertions use Playwright's auto-waiting until timeout.
*/
let
  python = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.playwright ]);
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
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
  find = target:
    if target.strategy == "role" then
      let roleAndName = builtins.match "([^\u0000]*)\u0000(.*)" target.value;
      in ''page.get_by_role(${builtins.toJSON (builtins.elemAt roleAndName 0)}, name=${builtins.toJSON (builtins.elemAt roleAndName 1)})''
    else
      ''page.${
        {
          label = "get_by_label";
          placeholder = "get_by_placeholder";
          text = "get_by_text";
          title = "get_by_title";
        }.${target.strategy}
      }(${builtins.toJSON target.value})'';
in
{
  testing.matchers = {
    toBeVisibleInBrowser = mkMatcher {
      accepts = [ "browserElement" ];
      run = _fixtures: target: mkAction "browserAssertion" {
        inherit (target) node description;
        code = run target.node ''${find target}.wait_for(state="visible", timeout=timeout_ms)'';
      };
    };
    toBeEnabled = mkMatcher {
      accepts = [ "browserElement" ];
      run = _fixtures: target: mkAction "browserAssertion" {
        inherit (target) node description;
        code = run target.node ''expect(${find target}).to_be_enabled(timeout=timeout_ms)'';
      };
    };
    toHaveValue = fixtures: target: expected: mkAction "browserAssertion" {
      inherit (target) node description;
      code = run target.node ''expect(${find target}).to_have_value(${builtins.toJSON expected}, timeout=timeout_ms)'';
    };
    toHaveLocation = fixtures: target: expected: mkAction "browserAssertion" {
      node = target.node;
      description = "browser location ${expected}";
      code = run target.node ''expect(page).to_have_url("**" + ${builtins.toJSON expected}, timeout=timeout_ms)'';
    };
    toHaveTitle = fixtures: target: expected: mkAction "browserAssertion" {
      node = target.node;
      description = "browser title ${expected}";
      code = run target.node ''expect(page).to_have_title(${builtins.toJSON expected}, timeout=timeout_ms)'';
    };
  };
}
