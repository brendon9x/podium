defmodule Podium do
  @moduledoc """
  Elixir library for generating PowerPoint (.pptx) files with editable charts.
  """

  alias Podium.{Presentation, Slide}

  @doc """
  Creates a new presentation.
  """
  def new do
    Presentation.new()
  end

  @doc """
  Adds a blank slide to the presentation.
  Returns `{presentation, slide}`.
  """
  def add_slide(prs, opts \\ []) do
    Presentation.add_slide(prs, opts)
  end

  @doc """
  Adds a text box to a slide.
  """
  def add_text_box(slide, text, opts) do
    Slide.add_text_box(slide, text, opts)
  end

  @doc """
  Adds a chart to a slide. Returns `{presentation, slide}`.
  """
  def add_chart(prs, slide, chart_type, chart_data, opts) do
    Presentation.add_chart(prs, slide, chart_type, chart_data, opts)
  end

  @doc """
  Replaces a slide in the presentation with an updated version.
  """
  def put_slide(prs, slide) do
    Presentation.put_slide(prs, slide)
  end

  @doc """
  Saves the presentation to a file.
  """
  def save(prs, path) do
    Presentation.save(prs, path)
  end

  @doc """
  Saves the presentation to an in-memory binary.
  """
  def save_to_memory(prs) do
    Presentation.save_to_memory(prs)
  end
end
