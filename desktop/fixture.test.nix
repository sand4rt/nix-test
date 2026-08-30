{ pkgs, ... }:
{
  test."observes a desktop window by its title" = { machine, desktop, expect }: [
    (machine.configure {
      modules = [
        {
          services.xserver.enable = true;
          services.xserver.displayManager.startx.enable = true;
          environment.systemPackages = [ pkgs.xterm ];
        }
      ];
    })
    (machine.command "startx ${pkgs.xterm}/bin/xterm -T 'Welcome' -- :0 >/tmp/x.log 2>&1 &")
    (expect.toBeVisible (desktop.getByWindow machine "Welcome"))
    (desktop.type machine "hello")
    (desktop.screenshot machine "welcome-window")
  ];
}
