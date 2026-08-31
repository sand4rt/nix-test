# Browser And Desktop

Browser tests favor accessibility-oriented locators rather than CSS selectors:

```nix
let button = browser.getByRole machine "button" { name = "Sign in"; }; in [
  (machine.configure { modules = [ browserPageModule ]; })
  (browser.configure machine)
  (browser.open machine "http://machine:8080/")
  (browser.fill (browser.getByLabel machine "Username") "example")
  (browser.click button)
  (expect.toBeVisible button)
]
```

Available browser locators include role, label, placeholder, text, and title.
Choose the locator closest to how a user identifies the element.

Desktop tests locate windows or visible text and can send keyboard input, type
text, and save screenshots:

```nix
[
  (machine.configure { modules = [ desktopModule ]; })
  (desktop.press machine "meta-ret")
  (expect.toBeVisible (desktop.getByWindow machine "Terminal"))
  (desktop.type machine "hello")
  (desktop.screenshot machine "desktop")
]
```

Both fixtures run on the machine backend and therefore require
`machine.configure` in the test.
