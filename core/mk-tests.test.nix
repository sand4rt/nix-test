{
  pkgs,
  builders,
  mkTests,
}:
let
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  actions = _: [ ];
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
    "browser"
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
  (builtInFixtures.machine.command "test -e ${builtInFixtures.filesystem.root}/file").command
  == "test -e /tmp/nix-test/file";
assert
  ((builtInFixtures.expect (builtInFixtures.machine.command "true")).toFail).code
  == ''machines["machine"].wait_until_fails("true")'';
assert builtins.attrNames builtInFixtures.machine == expectedMachineMethods;
assert (builtInFixtures.machines.node "server").name == "server";
assert
  ((builtInFixtures.expect ((builtInFixtures.machines.node "server").service "example")).toBeActive)
  .node == "server";
assert
  ((builtInFixtures.expect ((builtInFixtures.machines.node "server").file "/run/ready")).toExist)
  .command == "test -e /run/ready";
assert fails (builtInFixtures.filesystem.writeFile "../escape" "no");
assert fails (builtInFixtures.filesystem.remove "");
assert fails (builtInFixtures.filesystem.setMode "." "0700");
assert fails (builtInFixtures.network.endpoint {
  from = builtInFixtures.machine;
  port = 0;
});
assert fails (builtInFixtures.machine.endpoint.tcp 65536);
assert fails (mkTests {
  inherit pkgs;
  test = {
    configure.unknown = true;
    sample = actions;
  };
});
assert fails (mkTests {
  inherit pkgs;
  test = {
    configure.timeout = 0;
    sample = actions;
  };
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = actions;
  fixtures.terminal = builders.mkFixture (_: { });
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = actions;
  fixtures.custom = _: { };
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = actions;
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
  test.sample = _: [
    ((import ../step/fixture.nix builders).step "invalid" [ { type = "notAnAction"; } ])
  ];
});
assert fails (mkTests {
  inherit pkgs;
  test.sample = _: [
    (builtInFixtures.expect (builtInFixtures.terminal.getByText "wrong target")).toFail
  ];
});
assert
  (mkTests {
  inherit pkgs;
  test.sample = { machine, ... }: [ (machine.command "true") ];
  }).sample.nixTest == {
    backend = "machine";
    graphical = false;
  };
assert fails (mkTests {
  inherit pkgs;
  test.sample = { expect }: [ expect ];
});
assert
  (mkTests {
    inherit pkgs;
    test.sample = { terminal, ... }: [ terminal.print ];
  }).sample.nixTest == {
    backend = "terminal";
    graphical = false;
  };
assert
  (mkTests {
    inherit pkgs;
    test.sample = { machine, ... }: [ machine.browser.start ];
  }).sample.nixTest == {
    backend = "machine";
    graphical = true;
  };
pkgs.runCommand "nix-test-mk-tests-unit" { } ''
  touch "$out"
''
