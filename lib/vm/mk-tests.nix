{ pkgs, runner, cases }:
builtins.listToAttrs (
  builtins.map (case: {
    name = case.name;
    value = runner {
      inherit (case) name;
      homeModules = builtins.concatMap (action: action.homeModules) (
        builtins.filter (action: action.type == "vmConfigure") case.actions
      );
      testScript = ''
        machine.start()
        with subtest(${builtins.toJSON case.name}):
        ${pkgs.lib.concatMapStringsSep "\n" (action: "  " + action.code) (
          builtins.filter (action: action.type != "vmConfigure") case.actions
        )}
      '';
    };
  }) cases
)
