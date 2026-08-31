{ mkAction, ... }:
/**
  @doc assertions.results
  ## Saved results

  ```nix
  (expect result).toHaveExitCode expected
  (expect result).toHaveStdout expected
  (expect result).toContainStdout expected
  ```

  Result assertions inspect values saved by `machine.run` or `http.send` and do
  not repeat the original operation.
*/
{
  testing.matchers = {
    toHaveExitCode = fixtures: target: expected:
      assert target.type == "commandResult" || target.type == "resultExitCode";
      mkAction "resultAssertion" {
        inherit (target) name description;
        code = ''assert results[${builtins.toJSON target.name}][0] == ${toString expected}, results[${builtins.toJSON target.name}]'';
      };
    toHaveStdout = fixtures: target: expected:
      assert target.type == "commandResult" || target.type == "resultStdout";
      mkAction "resultAssertion" {
        inherit (target) name description;
        code = ''assert results[${builtins.toJSON target.name}][1] == ${builtins.toJSON expected}, results[${builtins.toJSON target.name}]'';
      };
    toContainStdout = fixtures: target: expected:
      assert target.type == "commandResult" || target.type == "resultStdout";
      mkAction "resultAssertion" {
        inherit (target) name description;
        code = ''assert ${builtins.toJSON expected} in results[${builtins.toJSON target.name}][1], results[${builtins.toJSON target.name}]'';
      };
  };
}
