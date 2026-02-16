defmodule Podium.MixProject do
  use Mix.Project

  @source_url "https://github.com/brendon9x/podium"

  def project do
    [
      app: :podium,
      version: "0.2.1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "Podium",
      description: "PowerPoint (.pptx) generation for Elixir with editable charts",
      source_url: @source_url
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixlsx, "~> 0.6"},
      {:sweet_xml, "~> 0.7", only: :test},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "overview",
      source_ref: "v0.2.1",
      source_url: @source_url,
      extra_section: "GUIDES",
      formatters: ["html", "markdown"],
      assets: %{"guides/assets" => "assets"},
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules()
    ]
  end

  defp extras do
    [
      # Introduction
      "guides/introduction/overview.md",
      "guides/introduction/installation.md",
      "guides/introduction/getting-started.md",

      # Core Features
      "guides/core/presentations-and-slides.md",
      "guides/core/text-and-formatting.md",
      "guides/core/shapes-and-styling.md",
      "guides/core/tables.md",
      "guides/core/charts.md",
      "guides/core/images.md",
      "guides/core/placeholders.md",

      # Advanced Features
      "guides/advanced/hyperlinks-and-actions.md",
      "guides/advanced/connectors-and-freeforms.md",
      "guides/advanced/combo-charts.md",
      "guides/advanced/video-and-media.md",
      "guides/advanced/slide-backgrounds-and-notes.md",

      # Recipes
      "guides/recipes/building-a-report.md",
      "guides/recipes/data-driven-slides.md",
      "guides/recipes/styling-patterns.md",

      # Cheatsheets
      "guides/cheatsheets/quick-reference.cheatmd"
    ]
  end

  defp groups_for_extras do
    [
      Introduction: ~r/guides\/introduction\//,
      "Core Features": ~r/guides\/core\//,
      "Advanced Features": ~r/guides\/advanced\//,
      Recipes: ~r/guides\/recipes\//,
      Cheatsheets: ~r/guides\/cheatsheets\//
    ]
  end

  defp groups_for_modules do
    [
      "Presentation API": [Podium, Podium.Presentation, Podium.Slide],
      "Shapes and Drawing": [
        Podium.Shape,
        Podium.AutoShapeType,
        Podium.Connector,
        Podium.Freeform,
        Podium.Drawing,
        Podium.Pattern
      ],
      "Text and Tables": [Podium.Text, Podium.Table],
      Charts: [
        Podium.Chart,
        Podium.Chart.ChartData,
        Podium.Chart.XyChartData,
        Podium.Chart.BubbleChartData,
        Podium.Chart.ComboChart,
        Podium.Chart.ChartType
      ],
      Media: [Podium.Image, Podium.Video],
      "Slide Content": [
        Podium.Placeholder,
        Podium.NotesSlide,
        Podium.CoreProperties,
        Podium.Units
      ],
      Internals: [
        Podium.TemplatePlaceholders,
        Podium.Chart.XmlWriter,
        Podium.Chart.XlsxWriter,
        Podium.OPC.Package,
        Podium.OPC.Relationships,
        Podium.OPC.ContentTypes,
        Podium.OPC.Constants,
        Podium.XML.Builder
      ]
    ]
  end
end
