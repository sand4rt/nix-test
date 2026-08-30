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
        builtins.hasAttr method fixture
        && (
          if method == "print" then
            !builtins.isAttrs fixture.print || (fixture.print._kind or null) != "action"
          else
            !builtins.isFunction fixture.${method}
        )
      ) methods;
    in
    assert lib.assertMsg (missing == [ ])
      "nix-test: ${name} does not implement the terminal fixture interface: missing ${builtins.concatStringsSep ", " missing}";
    assert lib.assertMsg (invalid == [ ])
      "nix-test: ${name} has invalid terminal fixture methods: ${builtins.concatStringsSep ", " invalid}";
    fixture;
}
