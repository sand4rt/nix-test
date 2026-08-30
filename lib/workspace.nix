{
  actions = {
    path = "$fixture";
    writeFile = path: content: {
      type = "writeFile";
      inherit path content;
    };
    require = packages: {
      type = "require";
      inherit packages;
    };
  };

  runtime = /* python */ ''
    import os

    def write_file(fixture, action):
        path = os.path.join(fixture, action["path"])
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as file:
            file.write(action["content"])
  '';
}
