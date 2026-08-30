{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  mkLocator,
  ...
}:
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
    get = node: request: target node "GET" request;
    getJson = node: request: (target node "GET" request) // { type = "httpJsonResponse"; };
    request = node: method: request: target node method request;
    send = node: request: mkAction "machineResult" {
      node = node.name;
      inherit (request) saveAs;
      command = command request;
      code = ''results[${builtins.toJSON request.saveAs}] = ${nodeExpression node.name}.execute(${builtins.toJSON (command request)})'';
    };
  });
}
