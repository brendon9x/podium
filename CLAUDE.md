# Podium

Elixir library for generating PowerPoint (.pptx) files.

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
