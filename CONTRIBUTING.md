# Contributing to Podium

Contributions are welcome! To make the best use of everyone's time, please **open an issue before starting work** so we can discuss whether the change fits the project's direction.

## Process

1. Open an issue describing what you'd like to add or change
2. Wait for a thumbs-up before investing time in code
3. Fork the repo and create a branch
4. Make your changes, then open a pull request

## Development Setup

```bash
git clone https://github.com/brendon9x/podium.git
cd podium
git submodule update --init   # pulls the python-pptx reference source
mix deps.get
mix test
```

Requires Elixir ~> 1.18.

## Working with the python-pptx Reference

Podium aims to match [python-pptx](https://github.com/scanny/python-pptx)'s feature set and test coverage. The source is available as a git submodule at `reference/python-pptx`.

When implementing a new feature:

1. Read the corresponding python-pptx code to understand how it structures its XML output
2. Look at the python-pptx tests to see what scenarios are covered
3. Port the behavior to idiomatic Elixir — don't transliterate Python line-by-line

Feature progress is tracked in `reference/FEATURES.md`. Keep it up to date when adding or completing features.

## Code Standards

- Run `mix format` before committing
- `mix test` must pass with no failures
- `mix compile --warnings-as-errors` must be clean
- Add tests that cover the same scenarios python-pptx tests for
- Add or update a demo script in `demos/` to exercise new features

## Releasing

While the library is 0.x, removals, signature changes and new features take a
minor bump; fixes take a patch bump.

1. Move the CHANGELOG's `Unreleased` section under a version heading with no
   date, with its sections in the order Added, Changed, Fixed, Removed
2. In the same commit, set `version` and `docs.source_ref` in `mix.exs` and the
   dependency constraint in `README.md` and
   `guides/introduction/installation.md`
3. Check that `mix precommit`, `mix docs --warnings-as-errors` and
   `mix hex.build` are clean
4. Commit as `Bump version to X.Y.Z`
5. Push `main` and wait for CI to pass
6. Tag `vX.Y.Z` and push the tag

Pushing the tag runs `.github/workflows/release.yml`, which publishes the
package and its documentation to Hex using the `HEX_API_KEY` repository secret.

## What Makes a Good PR

- **Focused** — one feature or fix per PR
- **Tested** — matching python-pptx's test coverage for the area you're touching
- **Demonstrated** — new features should appear in a demo script
- **Documented** — update `reference/FEATURES.md` and add ExDoc guide content where appropriate

## Scope

Podium is a create-only library. It reads a template package to build on, but we don't aim to open or edit existing decks. See the "Won't Implement" section of `reference/FEATURES.md` for other things that are explicitly out of scope.
