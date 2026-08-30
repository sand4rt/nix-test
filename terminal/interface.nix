{ lib }:
let
  methods = [
    "getByRegion"
    "getByText"
    "open"
    "press"
    "print"
  ];
in
{
  inherit methods;

  implement =
    name: fixture:
    let
      missing = builtins.filter (method: !(builtins.hasAttr method fixture)) methods;
      invalid = builtins.filter (
        method:
        builtins.hasAttr method fixture && method != "print" && !builtins.isFunction fixture.${method}
      ) methods;
    in
    assert lib.assertMsg (missing == [ ])
      "nix-testing: ${name} does not implement the terminal fixture interface: missing ${builtins.concatStringsSep ", " missing}";
    assert lib.assertMsg (invalid == [ ])
      "nix-testing: ${name} has invalid terminal fixture methods: ${builtins.concatStringsSep ", " invalid}";
    fixture;
}
