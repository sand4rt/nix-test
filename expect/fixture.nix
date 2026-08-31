{
  mkFixture,
  matcherFactories,
  ...
}:
/**
  @doc fixture.expect
  ## `expect`

  `expect` contains every built-in and custom matcher after it has been bound to
  the resolved fixture set. Matcher signatures are listed in the
  [Assertion API](assertions.md).
*/
{
  testing.fixtures.expect = mkFixture (
    fixtures: builtins.mapAttrs (_: factory: factory fixtures) matcherFactories
  );
}
