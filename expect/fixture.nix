{
  mkFixture,
  matcherFactories,
  ...
}:
{
  testing.fixtures.expect = mkFixture (
    fixtures: builtins.mapAttrs (_: factory: factory fixtures) matcherFactories
  );
}
