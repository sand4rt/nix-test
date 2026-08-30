/* python */ ''
  import json
  import sys
  import time

  from expect import assert_region, assert_text
  from terminal import Terminal
  from workspace import write_file

  def main():
      actions_path, fixture = sys.argv[1:]
      spec = json.load(open(actions_path))
      terminal = Terminal(spec["columns"], spec["rows"])
      try:
          for action in spec["testActions"]:
              action_type = action["type"]
              if action_type == "test":
                  print(f"\n--- {action['name']} ---", flush=True)
              elif action_type == "writeFile":
                  write_file(fixture, action)
              elif action_type == "open":
                  terminal.open(action["command"], fixture, spec["rows"], spec["columns"])
              elif action_type == "keys":
                  terminal.press(action["keys"])
              elif action_type == "print":
                  print("\n--- terminal ---")
                  print(terminal.text())
                  print("--- end terminal ---", flush=True)
              elif action_type == "assertRegion":
                  assert_region(terminal, action, spec["timeout"])
              elif action_type == "assertText":
                  assert_text(terminal, action["text"], spec["timeout"])
      finally:
          terminal.close()

  if __name__ == "__main__":
      main()
''
