{
  lib,
  pkgs,
  mkAction,
  ...
}:
/**
  @doc assertions.http
  ## HTTP

  ```nix
  expect.toHaveStatus expected response
  expect.toHaveBody response expected
  expect.toHaveHeader response { name, value }
  expect.toHaveJsonValue { actual, path, expected }
  ```

  HTTP matchers repeat the request until it matches or times out. Use them only
  with idempotent requests; use `http.send` for mutating requests.
*/
let
  assertion = target: command: mkAction "machinePredicate" {
    inherit (target) node description;
    inherit command;
  };
  curlCommand = target: extra: lib.concatStringsSep " " (
    [
      (lib.getExe pkgs.curl)
      "--silent"
      "--show-error"
      "--location"
      "--connect-timeout"
      "2"
      "--max-time"
      "5"
      "--request"
      target.method
    ]
    ++ lib.optional (target.body != null) "--data ${lib.escapeShellArg target.body}"
    ++ lib.optional (target.headers != { }) (lib.concatStringsSep " " (
      lib.mapAttrsToList (name: value: "-H ${lib.escapeShellArg "${name}: ${value}"}") target.headers
    ))
    ++ [ extra (lib.escapeShellArg target.url) ]
  );
in
{
  testing.matchers = {
    /**
      Assert that an HTTP response eventually has the expected status code.

      The request is repeated until it returns the expected status or the test
      timeout expires. Use this only with idempotent requests. Mutating requests
      should use `http.send` and saved-result assertions instead.

      # Example

      ```nix
      expect.toHaveStatus 200 (machine.http.get "http://localhost/health")
      ```
    */
    toHaveStatus = fixtures: expected: target:
      assertion target (
        curlCommand target "--output /dev/null --write-out '%{http_code}'"
        + " | grep -Fx ${lib.escapeShellArg (toString expected)}"
      );
    /** Assert that an HTTP response eventually contains visible body text. */
    toHaveBody = fixtures: target: expected:
      assertion target (curlCommand target "" + " | grep -F -- ${lib.escapeShellArg expected}");
    /** Assert that an HTTP response eventually contains an exact header. */
    toHaveHeader = fixtures: target: { name, value }:
      assertion target (
        curlCommand target "--dump-header - --output /dev/null"
        + " | tr -d '\\r' | grep -iFx -- ${lib.escapeShellArg "${name}: ${value}"}"
      );
    /** Assert that an HTTP JSON response eventually contains a value at a path. */
    toHaveJsonValue = fixtures: { actual, path, expected }:
      assertion actual (
        curlCommand actual "" + " | ${lib.getExe pkgs.jq} -e --argjson expected ${lib.escapeShellArg (builtins.toJSON expected)} "
        + lib.escapeShellArg ".${path} == \$expected"
      );
  };
}
