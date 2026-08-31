# I built a Playwright-inspired testing framework for Nix, and I'm looking for someone to take it forward

I was looking for a Nix testing framework with an experience similar to
Playwright, but I couldn't find one. Since my background is in web UI testing
and I previously worked on Playwright, I decided to experiment with building it
myself.

It currently includes fixtures and matchers for:

- Terminal applications
- NixOS VMs and multiple machines
- Services and filesystems
- HTTP and networking
- Containers and users
- Browser and desktop testing
- Missing something? Extend it with custom fixtures, locators, and matchers

A few examples:

```nix
# Test a terminal app built with Python
test."edits a file" = { terminal, filesystem }:
  let
    editor = pkgs.writeShellApplication {
      name = "tiny-editor";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        python -c '
import pathlib, sys
path = pathlib.Path(sys.argv[1])
path.write_text(input("Text: ") + "\\n")
print("Saved")
' "$@"
      '';
    };
  in [
    (filesystem.writeFile "example.txt" "")
    (terminal.open "${pkgs.lib.getExe editor} ${filesystem.root}/example.txt")
    (expect (terminal.getByText "Text:")).toBeVisible
    (terminal.press "Hello from Nix<enter>")
    (expect (terminal.getByText "Saved")).toBeVisible
    (terminal.open "cat ${filesystem.root}/example.txt")
    (expect (terminal.getByText "Hello from Nix")).toBeVisible
  ];

# Test a NixOS service
test."service starts" = { machine }: [
  (machine.configure { modules = [ ./configuration.nix ]; })
  (expect (machine.service "my-app.service")).toBeActive
  ((expect (machine.service "my-app.service").logs).toContain "ready")
];

# Test a declarative container
test."container starts" = { machine }:
  let 
    app = machine.container "app";
  in [
    (machine.configure {
      modules = [{
        containers.app = {
          autoStart = false;
          config.system.stateVersion = "25.11";
        };
      }];
    })
    app.start
    (expect app).toBeRunning
    (app.run "touch /run/ready")
    app.stop
    (expect app).toBeStopped
  ];
```

It runs as regular flake checks using a terminal runner or the NixOS test
driver. Much of it was built with AI assistance, with me guiding the API and
direction. It's still experimental, and I probably won't maintain it long term.
Would anyone be interested in taking it over?

Repository: **[insert repository link]**

I'd also value candid feedback: does a Playwright-style API make sense for Nix?
