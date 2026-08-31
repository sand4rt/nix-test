# Browser And Desktop

Browser tests favor accessibility-oriented locators rather than CSS selectors:

```nix
[
  (machine.configure { modules = [ browserPageModule ]; })
  machine.browser.start
  (machine.browser.open "http://machine:8080/")
  ((machine.browser.getByLabel "Username").fill "example")
  (machine.browser.getByRole "button" { name = "Sign in"; }).click
  (expect (machine.browser.getByText "Welcome, example")).toBeVisible
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
  (expect (desktop.getByWindow machine "Terminal")).toBeVisible
  (desktop.type machine "hello")
  (desktop.screenshot machine "desktop")
]
```

Both fixtures run on the machine backend and therefore require
`machine.configure` in the test.
