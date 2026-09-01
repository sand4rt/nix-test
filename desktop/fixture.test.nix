{ pkgs, expect, ... }:
{
  test."observes a desktop window by its title" = { machine, desktop }: [
    (machine.configure {
      modules = [
        {
          services.xserver.enable = true;
          services.xserver.displayManager.lightdm = {
            enable = true;
            greeter.enable = false;
          };
          services.xserver.displayManager.xserverArgs = [ "-ac" ];
          services.xserver.desktopManager.xterm.enable = true;
          services.xserver.displayManager.sessionCommands = ''
            ${pkgs.xterm}/bin/xterm -T Welcome -e ${pkgs.coreutils}/bin/sleep 60 &
          '';
          services.displayManager = {
            autoLogin = {
              enable = true;
              user = "test";
            };
            defaultSession = "xterm";
          };
          users.users.test = {
            isNormalUser = true;
          };
          environment.systemPackages = [ pkgs.xterm ];
        }
      ];
    })
    (expect (desktop.getByWindow machine "Welcome")).toBeVisible
    (desktop.type machine "hello")
    (desktop.screenshot machine "welcome-window")
  ];
}
