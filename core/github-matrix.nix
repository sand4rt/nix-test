/**
  @doc lib.mkGithubMatrix
  ## `lib.mkGithubMatrix`

  ```nix
  ciMatrix.${system} = inputs.tests.lib.mkGithubMatrix checks.${system};
  ```

  Creates a GitHub Actions matrix from a set of checks. Tests produced by
  `lib.mkTests` include backend metadata; other derivations are treated as
  regular builds. The result can be passed directly to `fromJSON`.
*/
checks:
{
  include = map (
    name:
    let
      metadata = checks.${name}.nixTest or { };
      backend = metadata.backend or "build";
      graphical = metadata.graphical or false;
    in
    {
      check = name;
      inherit backend;
      timeout = if graphical then 60 else if backend == "machine" then 45 else 15;
    }
  ) (builtins.attrNames checks);
}
