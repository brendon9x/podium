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
    * `:layout` - layout atom or integer index (1..11)
    * `:layout_index` - integer layout index (legacy, prefer `:layout`)

  ## Available layouts
    * `:title_slide` (1), `:title_content` (2), `:section_header` (3),
      `:two_content` (4), `:comparison` (5), `:title_only` (6),
      `:blank` (7), `:content_caption` (8), `:picture_caption` (9),
      `:title_vertical_text` (10), `:vertical_title_text` (11)
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

  @doc """
  Sets a picture placeholder on a slide. Returns `{presentation, slide}`.

  Only works on layouts with picture placeholders (e.g. `:picture_caption`).
  """
  def set_picture_placeholder(prs, slide, name, binary) do
    Presentation.set_picture_placeholder(prs, slide, name, binary)
  end

  @doc """
  Sets presentation-level footer, date, and slide number.

  ## Options
    * `:footer` - footer text string
    * `:date` - date text string
    * `:slide_number` - boolean, whether to show slide numbers
  """
  def set_footer(prs, opts) do
    Presentation.set_footer(prs, opts)
  end

  defp layout_atom(1), do: :title_slide
  defp layout_atom(2), do: :title_content
  defp layout_atom(3), do: :section_header
  defp layout_atom(4), do: :two_content
  defp layout_atom(5), do: :comparison
  defp layout_atom(6), do: :title_only
  defp layout_atom(7), do: :blank
  defp layout_atom(8), do: :content_caption
  defp layout_atom(9), do: :picture_caption
  defp layout_atom(10), do: :title_vertical_text
  defp layout_atom(11), do: :vertical_title_text

  defp layout_atom(n) when is_integer(n) do
    raise ArgumentError, "unknown layout index #{n}; expected 1..11"
  end

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
