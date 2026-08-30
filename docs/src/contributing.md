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

Backend `*.test.nix` files are black-box integration tests. They use public
fixtures, locators, and matchers to verify behavior visible from a terminal or
NixOS machine. Core `*.test.nix` files are unit-style evaluation checks for
builders, validation errors, and test compilation edge cases.

The documentation check fails when the committed API pages are stale or when
the site cannot be built.
