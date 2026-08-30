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
  /** Terminal PTY actions and terminal-cell locators. */
  inherit terminal;

  /** Isolated test workspace actions and path. */
  inherit workspace;

  /** NixOS machine configuration actions. */
  inherit vm;

  /** Playwright-style assertion factory for terminal and machine targets. */
  expect = target:
    if builtins.isString target then vmExpect target else terminalExpect target;
}
