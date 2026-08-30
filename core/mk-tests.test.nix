{ pkgs, builders, mkTests }:
let
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  callback = _: [ ];
in
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
assert (mkTests {
  inherit pkgs;
  test.sample = { terminal }: [ terminal.print ];
}).sample.type == "derivation";
pkgs.runCommand "nix-testing-mk-tests-unit" { } ''
  touch "$out"
''
