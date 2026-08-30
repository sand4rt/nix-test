let
  terminal =
    (import ./terminal/actions.nix)
    // (import ./terminal/terminal.nix).actions
    // (import ./terminal/locators.nix);

  workspace = (import ./workspace.nix).actions;
  terminalExpect = (import ./terminal/expect.nix).make;
  vm = import ./vm/actions.nix;
  vmExpect = import ./vm/expect.nix;
in
{
  /** Terminal PTY actions and terminal-cell locators. See the generated API reference. */
  inherit terminal;

  /** Isolated test workspace actions and path. See the generated API reference. */
  inherit workspace;

  /** NixOS machine configuration actions. See the generated API reference. */
  inherit vm;

  /** Retrying assertion factory for terminal and machine targets. See the generated API reference. */
  expect = target:
    if builtins.isString target then vmExpect target else terminalExpect target;
}
