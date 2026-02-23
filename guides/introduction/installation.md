# Installation

Add Podium to your Elixir project and verify it works with a quick smoke test.

## Add the Dependency

Add `podium` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:podium, "~> 0.2"}
  ]
end
```

Then fetch dependencies:

```bash
mix deps.get
```

## Verify It Works

Create a file called `verify.exs` and run it to confirm everything is set up:

```elixir
prs = Podium.new()
slide = Podium.Slide.new()
prs = Podium.add_slide(prs, slide)
Podium.save(prs, "verify.pptx")
IO.puts("Podium is working! Created verify.pptx")
```

```bash
mix run verify.exs
```

If you see the success message and can open `verify.pptx` in PowerPoint, LibreOffice, or Google Slides, you're all set.

## Dependencies

Podium depends on [elixlsx](https://hex.pm/packages/elixlsx) for generating the Excel workbooks embedded inside charts. This is pulled in automatically -- there are no native dependencies or external services to configure.

## Requirements

- Elixir >= 1.18
- Erlang/OTP (any version compatible with your Elixir)

Now that Podium is installed, work through the [Getting Started](getting-started.md) tutorial to build your first presentation.
