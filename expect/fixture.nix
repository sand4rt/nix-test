{
  matcherFactories,
  ...
}:
/**
  @doc fixture.expect
  ## `expect`

  Call `expect` with a locator to obtain its built-in and custom matchers.
  Matcher signatures are listed in the
  [Assertion API](assertions.md).
*/
{
  make =
    fixtures:
    let
      matchers = builtins.mapAttrs (_: factory: factory fixtures) matcherFactories;
    in
    {
      __functor = _self: target: builtins.mapAttrs (_: matcher: matcher target) matchers;
    };
}
