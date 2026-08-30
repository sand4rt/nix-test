{ mkAction, ... }:
{
  testing.matchers = {
    toHaveExitCode = fixtures: expected: target:
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
