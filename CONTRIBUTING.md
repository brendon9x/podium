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

## What Makes a Good PR

- **Focused** — one feature or fix per PR
- **Tested** — matching python-pptx's test coverage for the area you're touching
- **Demonstrated** — new features should appear in a demo script
- **Documented** — update `reference/FEATURES.md` and add ExDoc guide content where appropriate

## Scope

Podium is a create-only library. We don't aim to read or edit existing PowerPoint files. See the "Won't Implement" section of `reference/FEATURES.md` for other things that are explicitly out of scope.
