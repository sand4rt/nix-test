{
  lib,
  pkgs,
  mkAction,
  mkFixture,
  ...
}:
/**
  @doc fixture.machine
  ## `machine` and `machines`

  ```nix
  machine.configure { modules ? [ ]; }
  machines.configure { server.modules = [ ]; client.modules = [ ]; }
  machines.node name
  machine.command command
  machine.run { command, saveAs }
  machine.service name
  machine.userService user name
  machine.file path
  machine.directory path
  machine.symlink path
  machine.mount path
  machine.user name
  machine.container name
  machine.endpoint.tcp portOrOptions
  machine.endpoint.udp portOrOptions
  machine.http.get request
  machine.browser.start
  machine.browser.open url
  machine.browser.getByText text
  machine.open commandOrPackage
  machine.press keys
  machine.print
  machine.getByText text
  machine.getByPattern pattern
  machine.getByRegion { left ? 0, top ? 0, width ? null, height ? null }
  machine.start
  machine.shutdown
  machine.reboot
  machine.crash
  ```

  `machine` addresses the default VM. `machines.node name` returns the same
  per-machine interface for a named VM. Lifecycle properties and `print` are
  actions, not functions. The default VM needs no explicit configuration.
  Use `machine.configure` to add NixOS modules and `machines.configure` to define
  named-machine topology.
*/
let
  session = "nix-test";
  tmux = lib.getExe pkgs.tmux;
  filesystemRoot = "/tmp/nix-test";
  resolveFilesystemRoot = builtins.replaceStrings [ "$fixture" ] [ filesystemRoot ];
  nodeExpression = name: ''machines[${builtins.toJSON name}]'';
  commandAction =
    node: command:
    mkAction "machineAssertion" {
      inherit node;
      code = "${nodeExpression node}.succeed(${builtins.toJSON (resolveFilesystemRoot command)})";
    };
  keyNames = {
    "<bs>" = "BSpace";
    "<cr>" = "Enter";
    "<c-w>" = "C-w";
    "<enter>" = "Enter";
    "<esc>" = "Escape";
    "<escape>" = "Escape";
    "<leader>" = "Space";
    "<space>" = "Space";
    "<tab>" = "Tab";
  };
  sendKeys =
    sessionName: keys:
    lib.concatStringsSep " && " (
      builtins.map
        (
          part:
          if builtins.isList part then
            "${tmux} send-keys -t ${sessionName} ${keyNames.${builtins.head part}}"
          else
            "${tmux} send-keys -t ${sessionName} -l -- ${lib.escapeShellArg part}"
        )
        (
          builtins.filter (part: part != "") (
            builtins.split "(<bs>|<cr>|<c-w>|<enter>|<esc>|<escape>|<leader>|<space>|<tab>)" keys
          )
        )
    );
  makeMachine =
    name:
    let
      sessionName = if name == "machine" then session else "${session}-${name}";
    in
    {
      inherit name;

      command =
        command:
        let
          resolved = resolveFilesystemRoot command;
        in
        mkAction "machineCommand" {
          node = name;
          command = resolved;
          description = "command on ${name}";
          code = ''print(${nodeExpression name}.succeed(${builtins.toJSON resolved}), end="")'';
        };

      run =
        {
          command,
          saveAs,
        }:
        let resolved = resolveFilesystemRoot command;
        in mkAction "machineResult" {
          node = name;
          inherit saveAs;
          command = resolved;
          code = ''results[${builtins.toJSON saveAs}] = ${nodeExpression name}.execute(${builtins.toJSON resolved})'';
        };

      service = serviceName: {
        _kind = "locator";
        type = "service";
        node = name;
        name = serviceName;
        scope = "system";
        description = "system service ${serviceName}";
      };
      userService = user: serviceName: {
        _kind = "locator";
        type = "service";
        node = name;
        name = serviceName;
        scope = "user";
        inherit user;
        description = "user service ${serviceName}";
      };
      path = path: {
        _kind = "locator";
        type = "path";
        node = name;
        path = resolveFilesystemRoot path;
        kind = "path";
        description = "path ${path}";
      };
      file = path: (makeMachine name).path path // { kind = "file"; };
      directory = path: (makeMachine name).path path // { kind = "directory"; };
      symlink = path: (makeMachine name).path path // { kind = "symlink"; };
      mount = path: (makeMachine name).path path // { kind = "mount"; };
      user = userName: {
        _kind = "locator";
        type = "user";
        node = name;
        name = userName;
        description = "user ${userName}";
      };
      container = containerName: {
        _kind = "locator";
        type = "container";
        node = name;
        name = containerName;
        description = "container ${containerName}";
      };
      endpoint = {
        tcp = options:
          let
            host = if builtins.isInt options then "127.0.0.1" else options.host or "127.0.0.1";
            port = if builtins.isInt options then options else options.port;
          in
          assert builtins.isString host;
          assert builtins.isInt port && port > 0 && port <= 65535;
          {
          _kind = "locator";
          type = "endpoint";
          node = name;
          transport = "tcp";
          inherit host port;
          description = "TCP endpoint";
          };
        udp = options: (makeMachine name).endpoint.tcp options // { transport = "udp"; };
      };
      http = {
        get = request: {
          _kind = "locator";
          type = "httpResponse";
          node = name;
          method = "GET";
          url = if builtins.isString request then request else request.url;
          headers = if builtins.isString request then { } else request.headers or { };
          body = if builtins.isString request then null else request.body or null;
          description = "HTTP GET";
        };
      };

      getByText = text: {
        _kind = "locator";
        type = "machineText";
        node = name;
        inherit text;
        toBeVisible = mkAction "machineAssertion" {
          node = name;
          code = ''${nodeExpression name}.wait_until_succeeds(${builtins.toJSON (
            "${tmux} capture-pane -p -t ${sessionName} | grep -F -- ${lib.escapeShellArg text}"
          )})'';
        };
      };
      getByPattern = pattern: {
        _kind = "locator";
        type = "machinePattern";
        node = name;
        inherit pattern;
        toBeVisible = mkAction "machineAssertion" {
          node = name;
          code = ''${nodeExpression name}.wait_until_succeeds(${builtins.toJSON (
            "${tmux} capture-pane -p -t ${sessionName} | grep -E -- ${lib.escapeShellArg pattern}"
          )})'';
        };
      };
      getByRegion =
        options:
        let
          top = options.top or 0;
          left = options.left or 0;
          height = options.height or null;
          width = options.width or null;
          select = lib.concatStringsSep " | " (
            [ "${tmux} capture-pane -p -t ${sessionName}" ]
            ++ lib.optional (top > 0) "tail -n +${toString (top + 1)}"
            ++ lib.optional (height != null) "head -n ${toString height}"
            ++ lib.optional (left > 0) "cut -c ${toString (left + 1)}-"
            ++ lib.optional (width != null) "cut -c 1-${toString width}"
            ++ [ "sed 's/[[:space:]]*$//'" ]
          );
        in
        {
          _kind = "locator";
          type = "machineRegion";
          node = name;
          inherit left top width height;
          toEqual = expected:
            let
              normalized = lib.removeSuffix "\n" (lib.removePrefix "\n" expected);
              command = "test \"$(${select})\" = ${lib.escapeShellArg normalized}";
            in
            mkAction "machineAssertion" {
              node = name;
              code = ''${nodeExpression name}.wait_until_succeeds(${builtins.toJSON command})'';
            };
        };

      start = mkAction "machineLifecycle" {
        node = name;
        operation = "start";
        code = "${nodeExpression name}.start()";
      };
      shutdown = mkAction "machineLifecycle" {
        node = name;
        operation = "shutdown";
        code = "${nodeExpression name}.shutdown()";
      };
      reboot = mkAction "machineLifecycle" {
        node = name;
        operation = "reboot";
        code = "${nodeExpression name}.reboot()";
      };
      crash = mkAction "machineLifecycle" {
        node = name;
        operation = "crash";
        code = "${nodeExpression name}.crash()";
      };

      open =
        command:
        let
          executable = resolveFilesystemRoot (if builtins.isString command then command else lib.getExe command);
        in
        commandAction name (
          "mkdir -p ${filesystemRoot}"
          + " && ${tmux} new-session -d -x 140 -y 42 -c ${filesystemRoot} -s ${sessionName} "
          + lib.escapeShellArg executable
        );
      press = keys: commandAction name (sendKeys sessionName keys);
      print = mkAction "machineAssertion" {
        node = name;
        code = "print(${nodeExpression name}.succeed(${builtins.toJSON "${tmux} capture-pane -p -t ${sessionName}"}))";
      };
    };
in
{
  testing.fixtures.machine = mkFixture (_fixtures: (makeMachine "machine") // {
    /**
      @doc machine.configure
      ## `machine.configure`

      ```nix
      machine.configure {
        modules = [ module ];
      }
      ```

      Selects the NixOS machine backend and configures its NixOS modules. `modules`
      defaults to an empty list.
    */
    configure =
      options:
      mkAction "machineConfigure" {
        nodes.machine.modules = options.modules or [ ];
      };
  });

  testing.fixtures.machines = mkFixture (_fixtures: {
    node = makeMachine;
    configure =
      nodes:
      mkAction "machineConfigure" {
        nodes = builtins.mapAttrs (_: options: {
          modules = options.modules or [ ];
        }) nodes;
      };
  });
}
