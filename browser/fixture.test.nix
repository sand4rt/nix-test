{ pkgs, ... }:
{
  test."signs in through accessible controls" = { machine, browser, expect }: let
    page = pkgs.writeTextDir "index.html" ''
      <!doctype html>
      <html>
        <head><title>Account</title></head>
        <body>
          <label for="username">Username</label>
          <input id="username" placeholder="Your username">
          <button type="button" onclick="document.querySelector('main').textContent = 'Welcome, ' + document.querySelector('#username').value">Sign in</button>
          <main></main>
        </body>
      </html>
    '';
  in [
    (machine.configure {
      modules = [
        {
          systemd.services.web = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.ExecStart = "${pkgs.python3}/bin/python -m http.server 8080 --directory ${page}";
          };
        }
      ];
    })
    (browser.configure machine)
    (browser.open machine "http://machine:8080/")
    (browser.fill (browser.getByLabel machine "Username") "Ada")
    (expect.toHaveValue (browser.getByLabel machine "Username") "Ada")
    (browser.click (browser.getByRole machine "button" { name = "Sign in"; }))
    (expect.toBeVisible (browser.getByText machine "Welcome, Ada"))
    (expect.toHaveTitle machine "Account")
  ];
}
