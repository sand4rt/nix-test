final: prev:
let
  builders = import ./core/builders.nix;
  fixtures = import ./core/fixtures.nix {
    pkgs = final;
    lib = final.lib;
  };
  terminalModule = import ./terminal/fixture.nix {
    lib = final.lib;
    inherit (builders) mkAction mkFixture;
  };
  terminalFixture = terminalModule.testing.fixtures.terminal;
  /** @doc testers.runTUITest
  ## `testers.runTUITest`

  ```nix
  pkgs.testers.runTUITest {
    name = "example";
    tests = { test, ... }: [ ];
    columns = 140;
    rows = 42;
    timeout = 15;
  }
  ```

  Builds one terminal test derivation. `columns`, `rows`, and `timeout` are
  optional and default to `140`, `42`, and `15` seconds respectively. Prefer
  `lib.mkTests` for independent flake checks; use this lower-level API when a
  single derivation should contain several terminal cases.
  */
  runTUITest =
    {
        name,
        tests,
        columns ? 140,
        rows ? 42,
        timeout ? 15,
      }:
      let
        actions = tests {
          inherit columns rows;
          test = name: callback: {
            inherit name;
            actions = callback fixtures;
          };
        };
        testActions = builtins.concatMap (
          test:
          [
            {
              type = "test";
              inherit (test) name;
            }
          ]
          ++ test.actions
        ) actions;
        workspaceSources = builtins.concatMap (
          action: final.lib.optional (action ? source) action.source
        ) testActions;
        script = final.writeText "${name}-actions.json" (builtins.toJSON {
          inherit testActions;
          inherit columns rows timeout;
        });
        runner = final.writeTextDir "tui_test/runner.py" /* python */ ''
          import json
          import sys

          from expect import assert_region, assert_text
          from terminal import Terminal
          from workspace import write_file
          from workspace import apply_workspace_action


          def run_action(action, terminal, fixture, spec):
              action_type = action["type"]
              if action_type in {"test", "step"}:
                  print(f"\n--- {action['name']} ---", flush=True)
                  for nested in action.get("actions", []):
                      run_action(nested, terminal, fixture, spec)
              elif action_type == "writeFile":
                  write_file(fixture, action)
              elif action_type in {"makeDirectory", "copyFile", "copyTree", "symlink", "setMode", "removePath"}:
                  apply_workspace_action(fixture, action)
              elif action_type == "open":
                  terminal.open(action["command"], fixture, spec["rows"], spec["columns"])
              elif action_type == "keys":
                  terminal.press(action["keys"])
              elif action_type == "print":
                  print("\n--- terminal ---")
                  print(terminal.text())
                  print("--- end terminal ---", flush=True)
              elif action_type == "assertRegion":
                  assert_region(terminal, action, spec["timeout"])
              elif action_type == "assertText":
                  assert_text(terminal, action["text"], spec["timeout"])
              else:
                  raise ValueError(f"unsupported terminal action: {action_type}")


          def main():
              actions_path, fixture = sys.argv[1:]
              spec = json.load(open(actions_path))
              terminal = Terminal(spec["columns"], spec["rows"])
              try:
                  for action in spec["testActions"]:
                      run_action(action, terminal, fixture, spec)
              finally:
                  terminal.close()


          if __name__ == "__main__":
              main()
        '';
        terminal = final.writeTextDir "tui_test/terminal.py" terminalFixture.runtime;
        workspace = final.writeTextDir "tui_test/workspace.py" /* python */ ''
          from pathlib import Path
          import shutil


          def write_file(fixture, action):
              path = Path(fixture, action["path"])
              path.parent.mkdir(parents=True, exist_ok=True)
              path.write_text(action["content"])


          def apply_workspace_action(fixture, action):
              root = Path(fixture).resolve()
              path = root / action["path"]
              parent = path.parent.resolve()
              if root not in parent.parents and parent != root:
                  raise ValueError(f"workspace path escapes fixture: {action['path']}")
              action_type = action["type"]
              if action_type == "makeDirectory":
                  path.mkdir(parents=True, exist_ok=True)
              elif action_type == "copyFile":
                  path.parent.mkdir(parents=True, exist_ok=True)
                  shutil.copyfile(action["source"], path)
              elif action_type == "copyTree":
                  shutil.copytree(action["source"], path, dirs_exist_ok=True)
              elif action_type == "symlink":
                  path.parent.mkdir(parents=True, exist_ok=True)
                  path.unlink(missing_ok=True)
                  path.symlink_to(action["target"])
              elif action_type == "setMode":
                  path.chmod(int(action["mode"], 8))
              elif action_type == "removePath":
                  if path.is_dir() and not path.is_symlink():
                      shutil.rmtree(path)
                  else:
                      path.unlink(missing_ok=True)
        '';
        locators = final.writeTextDir "tui_test/locators.py" /* python */ ''
          def region(terminal, locator):
              lines = terminal.text().splitlines()
              selected = lines[locator["top"]:]
              selected = [line[locator["left"]:] for line in selected]
              if locator["height"] is not None:
                  selected = selected[:locator["height"]]
              if locator["width"] is not None:
                  selected = [line[:locator["width"]] for line in selected]
              return "\n".join(selected).rstrip()
        '';
        expect = final.writeTextDir "tui_test/expect.py" (import ./terminal/assertions.nix { inherit (builders) mkAction; }).runtime;
      in
      final.runCommand name
        {
          nativeBuildInputs = [
            (final.python313.withPackages (pythonPackages: [
              pythonPackages.pexpect
              pythonPackages.pyte
            ]))
          ];
          inherit workspaceSources;
        }
        ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME" "$TMPDIR/project"
          PYTHONPATH=${runner}/tui_test:${terminal}/tui_test:${workspace}/tui_test:${locators}/tui_test:${expect}/tui_test:$PYTHONPATH python ${runner}/tui_test/runner.py ${script} "$TMPDIR/project"
          touch "$out"
        '';
  /** @doc testers.testCase
  ## `testers.testCase`

  ```nix
  pkgs.testers.testCase name callback
  ```

  Constructs a named test-case value for callers using the overlay API.
  */
  testCase = name: callback: {
    inherit name callback;
  };
  runNixOSTest = prev.testers.runNixOSTest;
in
{
  testers = prev.testers // {
    tui = runTUITest;
    inherit testCase;
    /** @doc testers.test
    ## `testers.test`

    ```nix
    pkgs.testers.test { type = "tui"; name = "example"; tests = tests; }
    pkgs.testers.test { type = "nixos"; name = "example"; testScript = testScript; }
    ```

    Dispatches to the terminal or NixOS test runner. `type` defaults to `"tui"`
    and may be `"tui"` or `"nixos"`.
    */
    test = args:
      if (args.type or "tui") == "tui" then
        runTUITest (builtins.removeAttrs args [ "type" "extraPackages" "packages" ])
      else if args.type == "nixos" then
        runNixOSTest (builtins.removeAttrs args [ "type" ])
      else
        throw "testing-library: unsupported test type '${args.type}' (expected \"tui\" or \"nixos\")";
    inherit runTUITest runNixOSTest;
  };
}
