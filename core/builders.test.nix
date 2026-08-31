{ pkgs, builders }:
let
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  action = builders.mkAction "sampleAction" { value = 1; };
  fixture = builders.mkFixture (_: { value = 1; });
  locator = builders.mkLocator { type = "sampleLocator"; value = 1; };
  otherLocator = builders.mkLocator { type = "otherLocator"; value = 1; };
  matcher = builders.mkMatcher {
    accepts = [ "sampleLocator" ];
    run = _: value: builders.mkAction "sampleAssertion" {
      inherit (value) value;
    };
  };
in
assert action == {
  _kind = "action";
  type = "sampleAction";
  value = 1;
};
assert fixture._kind == "fixture";
assert fixture.factory { } == { value = 1; };
assert locator == {
  _kind = "locator";
  type = "sampleLocator";
  value = 1;
};
assert (matcher { } locator).type == "sampleAssertion";
assert fails (matcher { } otherLocator);
assert (builders.mkAction "expected" { _kind = "wrong"; type = "wrong"; }).type == "expected";
assert (builders.mkAction "expected" { _kind = "wrong"; })._kind == "action";
assert (builders.mkLocator { _kind = "wrong"; type = "sample"; })._kind == "locator";
pkgs.runCommand "nix-test-builders-unit" { } ''
  touch "$out"
''
