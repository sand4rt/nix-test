{ pkgs }:
let
  builders = import ../core/builders.nix;
  fixtures = import ../core/fixtures.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  terminalModule = import ./fixture.nix {
    inherit (pkgs) lib;
    inherit (builders) mkAction mkFixture;
  };
  terminalFixture = terminalModule.testing.fixtures.terminal;
in
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
  filesystemSources = builtins.concatMap (
    action: pkgs.lib.optional (action ? source) action.source
  ) testActions;
  script = pkgs.writeText "${name}-actions.json" (builtins.toJSON {
    inherit testActions;
    inherit columns rows timeout;
  });
  runner = pkgs.writeTextDir "tui_test/runner.py" /* python */ ''
    import json
    import sys

    from expect import assert_region, assert_text
    from terminal import Terminal
    from filesystem import write_file
    from filesystem import apply_filesystem_action


    def run_action(action, terminal, fixture, spec):
        action_type = action["type"]
        if action_type in {"test", "step"}:
            print(f"\n--- {action['name']} ---", flush=True)
            for nested in action.get("actions", []):
                run_action(nested, terminal, fixture, spec)
        elif action_type == "writeFile":
            write_file(fixture, action)
        elif action_type in {"makeDirectory", "copyFile", "copyTree", "symlink", "setMode", "removePath"}:
            apply_filesystem_action(fixture, action)
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
  terminal = pkgs.writeTextDir "tui_test/terminal.py" terminalFixture.runtime;
  filesystem = pkgs.writeTextDir "tui_test/filesystem.py" /* python */ ''
    from pathlib import Path
    import shutil


    def write_file(fixture, action):
        root = Path(fixture).resolve()
        path = root / action["path"]
        path.parent.mkdir(parents=True, exist_ok=True)
        resolved = path.resolve()
        if root not in resolved.parents:
            raise ValueError(f"filesystem path escapes fixture: {action['path']}")
        path.write_text(action["content"])


    def apply_filesystem_action(fixture, action):
        root = Path(fixture).resolve()
        path = root / action["path"]
        parent = path.parent.resolve()
        if root not in parent.parents and parent != root:
            raise ValueError(f"filesystem path escapes fixture: {action['path']}")
        action_type = action["type"]
        if action_type == "makeDirectory":
            path.mkdir(parents=True, exist_ok=True)
        elif action_type == "copyFile":
            path.parent.mkdir(parents=True, exist_ok=True)
            resolved = path.resolve()
            if root not in resolved.parents:
                raise ValueError(f"filesystem path escapes fixture: {action['path']}")
            shutil.copyfile(action["source"], path)
        elif action_type == "copyTree":
            resolved = path.resolve()
            if root not in resolved.parents:
                raise ValueError(f"filesystem path escapes fixture: {action['path']}")
            shutil.copytree(action["source"], path, dirs_exist_ok=True)
        elif action_type == "symlink":
            path.parent.mkdir(parents=True, exist_ok=True)
            path.unlink(missing_ok=True)
            path.symlink_to(action["target"])
        elif action_type == "setMode":
            resolved = path.resolve()
            if root not in resolved.parents:
                raise ValueError(f"filesystem path escapes fixture: {action['path']}")
            path.chmod(int(action["mode"], 8))
        elif action_type == "removePath":
            if path.is_dir() and not path.is_symlink():
                shutil.rmtree(path)
            else:
                path.unlink(missing_ok=True)
  '';
  locators = pkgs.writeTextDir "tui_test/locators.py" /* python */ ''
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
  expect = pkgs.writeTextDir "tui_test/expect.py" (
    import ./assertions.nix { inherit (builders) mkAction; }
  ).runtime;
in
pkgs.runCommand name
  {
    nativeBuildInputs = [
      (pkgs.python313.withPackages (pythonPackages: [
        pythonPackages.pexpect
        pythonPackages.pyte
      ]))
    ];
    inherit filesystemSources;
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" "$TMPDIR/project"
    PYTHONPATH=${runner}/tui_test:${terminal}/tui_test:${filesystem}/tui_test:${locators}/tui_test:${expect}/tui_test:$PYTHONPATH python ${runner}/tui_test/runner.py ${script} "$TMPDIR/project"
    touch "$out"
  ''
