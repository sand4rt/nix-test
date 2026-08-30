# Contributing to the Docs

Narrative guides live in `docs/src`. A Nix expression generates the API
reference from `/** @doc name ... */` comments beside public declarations.

After changing an API comment, regenerate the reference:

```sh
nix run .#generate-docs
```

Build the site locally:

```sh
nix build .#docs
```

The generated site is available through the `result` symlink. Run all checks
before submitting a change:

```sh
nix flake check
```

The documentation check fails when the committed API page is stale or when the
site cannot be built.
