{ pkgs, expect, ... }:
{
  test."signs in through accessible controls" = { machine }:
  let
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
    (expect (machine.service "web.service")).toBeActive
    machine.browser.start
    (machine.browser.open "http://machine:8080/")
    ((machine.browser.getByLabel "Username").fill "Ada")
    ((expect (machine.browser.getByLabel "Username")).toHaveValue "Ada")
    (machine.browser.getByRole "button" { name = "Sign in"; }).click
    (expect (machine.browser.getByText "Welcome, Ada")).toBeVisible
    ((expect machine.browser).toHaveTitle "Account")
  ];
}
