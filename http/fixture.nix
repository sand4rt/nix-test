{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
/**
  @doc fixture.http
  ## `http`

  ```nix
  http.get machine request
  http.getJson machine request
  http.request machine method request
  http.send machine {
    method = "POST";
    url = "http://localhost/items";
    headers = { };
    body = null;
    saveAs = "create-item";
  }
  ```

  A request may be a URL string or `{ url, headers ? { }, body ? null }`.
  Observation methods return retryable locators and must be idempotent.
  `send` executes once and stores a command result under `saveAs`.
*/
let
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  target = machine: method: request:
    let options = if builtins.isString request then { url = request; } else request;
    in mkLocator {
      type = "httpResponse";
      node = machine.name;
      inherit method;
      url = options.url;
      headers = options.headers or { };
      body = options.body or null;
      description = "${method} ${options.url}";
    };
  command = { method, url, headers ? { }, body ? null, ... }:
    lib.concatStringsSep " " (
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
        method
      ]
      ++ lib.optional (headers != { }) (lib.concatStringsSep " " (
        lib.mapAttrsToList (name: value: "-H ${lib.escapeShellArg "${name}: ${value}"}") headers
      ))
      ++ lib.optional (body != null) "--data ${lib.escapeShellArg body}"
      ++ [ (lib.escapeShellArg url) ]
    );
in
{
  testing.fixtures.http = mkFixture (_fixtures: {
    /** Locate the response to an idempotent GET request. */
    get = node: request: target node "GET" request;
    /** Locate a JSON response to an idempotent GET request. */
    getJson = node: request: (target node "GET" request) // { type = "httpJsonResponse"; };
    /** Locate the response to an idempotent request. */
    request = node: method: request: target node method request;
    /** Send one request once and save its result by name. */
    send = node: request: mkAction "machineResult" {
      node = node.name;
      inherit (request) saveAs;
      command = command request;
      code = ''results[${builtins.toJSON request.saveAs}] = ${nodeExpression node.name}.execute(${builtins.toJSON (command request)})'';
    };
  });
}
