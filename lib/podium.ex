defmodule Podium do
  @moduledoc """
  Elixir library for generating PowerPoint (.pptx) files with editable charts.
  """

  alias Podium.{Placeholder, Presentation, Slide}

  @doc """
  Creates a new presentation.

  ## Options
    * `:slide_width` - slide width, default 16:9 (12_192_000 EMU). Accepts EMU integer or `{value, unit}`.
    * `:slide_height` - slide height, default 16:9 (6_858_000 EMU). Accepts EMU integer or `{value, unit}`.
  """
  def new(opts \\ []) do
    Presentation.new(opts)
  end

  @doc """
  Adds a slide to the presentation.
  Returns `{presentation, slide}`.

  ## Options
    * `:layout` - layout atom (`:title_slide`, `:title_content`, `:blank`) or integer index
    * `:layout_index` - integer layout index (legacy, prefer `:layout`)
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
  Adds an image to a slide. Returns `{presentation, slide}`.

  Image format is auto-detected from magic bytes (PNG/JPEG).
  """
  def add_image(prs, slide, binary, opts) do
    Presentation.add_image(prs, slide, binary, opts)
  end

  @doc """
  Adds a text box with a picture (blip) fill to a slide. Returns `{presentation, slide}`.
  """
  def add_picture_fill_text_box(prs, slide, text, image_binary, opts) do
    Presentation.add_picture_fill_text_box(prs, slide, text, image_binary, opts)
  end

  @doc """
  Adds a table to a slide.

  `rows` is a list of lists where each inner list is a row of cell values.
  Cell values can be plain strings or rich text.
  """
  def add_table(slide, rows, opts) do
    Slide.add_table(slide, rows, opts)
  end

  @doc """
  Sets a placeholder's text content on a slide.

  The slide must have been created with a layout that has the given placeholder.
  """
  def set_placeholder(slide, name, text) do
    layout = layout_atom(slide.layout_index)
    ph = Placeholder.new(layout, name, text)
    %{slide | placeholders: slide.placeholders ++ [ph]}
  end

  defp layout_atom(1), do: :title_slide
  defp layout_atom(2), do: :title_content
  defp layout_atom(7), do: :blank
  defp layout_atom(n) when is_integer(n), do: :blank

  @doc """
  Sets core document properties (Dublin Core metadata).

  ## Options
    * `:title` - document title
    * `:author` - document author
    * `:subject` - document subject
    * `:keywords` - keywords
    * `:category` - category
    * `:comments` - comments/description
    * `:last_modified_by` - last modified by
  """
  def set_core_properties(prs, opts) do
    Presentation.set_core_properties(prs, opts)
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
