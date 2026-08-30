{
  pkgs,
  builders,
  mkTests,
}:
let
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  callback = _: [ ];
  terminalInterface = import ../terminal/interface.nix { inherit (pkgs) lib; };
  terminalImplementation = {
    getByRegion = _: { };
    getByText = _: { };
    open = _: { };
    press = _: { };
    print = builders.mkAction "print" { };
    backendOnly = true;
  };
  builtInFixtures = import ./fixtures.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };
  expectedMachineMethods = [
    "command"
    "configure"
    "container"
    "crash"
    "directory"
    "endpoint"
    "file"
    "getByPattern"
    "getByRegion"
    "getByText"
    "http"
    "mount"
    "name"
    "open"
    "path"
    "press"
    "print"
    "reboot"
    "run"
    "service"
    "shutdown"
    "start"
    "symlink"
    "user"
    "userService"
  ];
in
assert (terminalInterface.implement "test" terminalImplementation).backendOnly;
assert fails (
  terminalInterface.implement "test" (builtins.removeAttrs terminalImplementation [ "open" ])
);
assert fails (terminalInterface.implement "test" (terminalImplementation // { press = { }; }));
assert fails (terminalInterface.implement "test" (terminalImplementation // { print = _: { }; }));
assert
  (builtInFixtures.machine.command "test -e ${builtInFixtures.workspace.path}/file").command
  == "test -e /tmp/nix-test/file";
assert
  (builtInFixtures.expect.toFail (builtInFixtures.machine.command "true")).code
  == ''machines["machine"].wait_until_fails("true")'';
assert builtins.attrNames builtInFixtures.machine == expectedMachineMethods;
assert (builtInFixtures.machines.node "server").name == "server";
assert
  (builtInFixtures.expect.toBeActive ((builtInFixtures.machines.node "server").service "example"))
  .node == "server";
assert
  (builtInFixtures.expect.toExist ((builtInFixtures.machines.node "server").file "/run/ready"))
  .command == "test -e /run/ready";
assert fails (builtInFixtures.workspace.writeFile "../escape" "no");
assert fails (mkTests {
  inherit pkgs;
  test = {
    configure.unknown = true;
    sample = callback;
  };
});
assert fails (mkTests {
  inherit pkgs;
  test = {
    configure.timeout = 0;
    sample = callback;
  };
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = callback;
  fixtures.terminal = builders.mkFixture (_: { });
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = callback;
  fixtures.custom = _: { };
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = callback;
  locators.missing.getByName = _: builders.mkLocator { type = "missing"; };
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = callback;
  matchers.toBeVisible = builders.mkMatcher {
    run = _: target: target;
  };
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = _: [ { type = "notAnAction"; } ];
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = { terminal, expect, ... }: [
    (expect.toFail (terminal.getByText "wrong target"))
  ];
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = { missingFixture }: [ missingFixture ];
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = { machine }: [ (machine.command "true") ];
});
assert
  (mkTests {
    inherit pkgs;
    test.sample = { terminal }: [ terminal.print ];
  }).sample.type == "derivation";
pkgs.runCommand "nix-test-mk-tests-unit" { } ''
  touch "$out"
''
