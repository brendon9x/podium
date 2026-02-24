# Podium

Elixir library aiming to be a robust PowerPoint (.pptx) generation library for Elixir. We use [python-pptx](https://github.com/scanny/python-pptx) as our reference implementation — the goal is to match its features and test coverage except for niche cases. Also, we're not aiming to have a library that can read and edit Powerpoint.

## Project Goals

- Port python-pptx's feature set to idiomatic Elixir as tracked in `reference/FEATURES.md`
- Match python-pptx's test coverage — aim to cover the same scenarios they test
- Keep `reference/FEATURES.md` up to date as features are implemented
- Exercise all features in demo files under `demos/` — number of demo files is at discretion, but every feature should be demonstrated

## Reference: python-pptx

The python-pptx source is available as a git submodule at `reference/python-pptx`. If it's not checked out, run:

```
git submodule update --init
```

Use it to understand how python-pptx structures its XML output, what edge cases it handles, and what tests it runs. When implementing a new feature, start by reading the corresponding python-pptx code and tests.

## Git Workflow

- Never commit directly to main — always create a feature branch first
- Use feature branches for all work, then open a PR

## Running Tests

- Run the full test suite: `mix test`
- Run a specific test file: `mix test test/path/to/test.exs`
- Run a specific test: `mix test test/path/to/test.exs:42`
- Always run `mix test` after making changes to verify nothing is broken
- Run `mix format` after every edit
- Never commit with broken tests or compiler warnings

## Code Style

- Use `mix format` before committing
- No backwards compatibility shims — just change the code
- When creating a LiveView component function, add `:attr` annotations
