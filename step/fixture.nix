{ mkAction, mkFixture, ... }:
{
  testing.fixtures.step = mkFixture (_fixtures: name: actions: mkAction "step" {
    inherit name actions;
  });
}
