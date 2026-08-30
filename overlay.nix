final: prev:
let
  terminalActions = (import ./lib/terminal/actions.nix)
    // (import ./lib/terminal/terminal.nix).actions
    // (import ./lib/terminal/locators.nix);
  workspaceActions = (import ./lib/workspace.nix).actions;
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
            actions = callback {
              terminal = terminalActions;
              workspace = workspaceActions;
              expect = (import ./lib/terminal/expect.nix).make;
            };
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
        packages = builtins.concatMap (action: action.packages) (
          builtins.filter (action: action.type == "require") testActions
        );
        runtimeActions = builtins.filter (action: action.type != "require") testActions;
        script = final.writeText "${name}-actions.json" (builtins.toJSON {
          testActions = runtimeActions;
          inherit columns rows timeout;
        });
        runner = final.writeTextDir "tui_test/runner.py" (import ./lib/runner.nix);
        terminal = final.writeTextDir "tui_test/terminal.py" (import ./lib/terminal/terminal.nix).runtime;
        workspace = final.writeTextDir "tui_test/workspace.py" (import ./lib/workspace.nix).runtime;
        locators = final.writeTextDir "tui_test/locators.py" (import ./lib/terminal/locators.nix).runtime;
        expect = final.writeTextDir "tui_test/expect.py" (import ./lib/terminal/expect.nix).runtime;
      in
      final.runCommand name
        {
          nativeBuildInputs = [
            (final.python313.withPackages (pythonPackages: [
              pythonPackages.pexpect
              pythonPackages.pyte
            ]))
          ] ++ packages;
        }
        ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME" "$TMPDIR/project"
          PYTHONPATH=${runner}/tui_test:${terminal}/tui_test:${workspace}/tui_test:${locators}/tui_test:${expect}/tui_test:$PYTHONPATH python ${runner}/tui_test/runner.py ${script} "$TMPDIR/project"
          touch "$out"
        '';
  testCase = name: callback: {
    inherit name callback;
  };
  runNixOSTest = prev.testers.runNixOSTest;
in
{
  testers = prev.testers // {
    tui = runTUITest;
    inherit testCase;
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
