defmodule Podium do
  @moduledoc """
  Elixir library for generating PowerPoint (.pptx) files with editable charts.

  Podium provides a functional API for building presentations programmatically.
  Create a presentation with `new/1`, add slides with `add_slide/2`, then populate
  them with text boxes, charts, images, tables, and shapes.

  ## Text Formatting Reference

  Text content can be a plain string or rich text (a list of paragraphs).

  ### Run options

  Each run is a `{text, opts}` tuple. Available options:

    * `:font_size` - font size in points (e.g. `12`)
    * `:bold` - `true` to bold
    * `:italic` - `true` to italicize
    * `:underline` - `true` for single underline, or one of `:single`, `:double`,
      `:heavy`, `:dotted`, `:dotted_heavy`, `:dash`, `:dash_heavy`, `:dash_long`,
      `:dash_long_heavy`, `:dot_dash`, `:dot_dash_heavy`, `:dot_dot_dash`,
      `:dot_dot_dash_heavy`, `:wavy`, `:wavy_heavy`, `:wavy_double`, `:words`
    * `:strikethrough` - `true` for single strikethrough
    * `:superscript` - `true` for superscript
    * `:subscript` - `true` for subscript
    * `:color` - hex RGB string (e.g. `"FF0000"`)
    * `:font` - font family name (e.g. `"Arial"`)
    * `:hyperlink` - URL string, `[url: "...", tooltip: "..."]`,
      `{:slide, slide}` for slide-to-slide links, or an action atom
      (`:next_slide`, `:previous_slide`, `:first_slide`, `:last_slide`, `:end_show`)
    * `:lang` - language code (default `"en-US"`)

  ### Paragraph options

  When using `{runs, opts}` tuple paragraphs:

    * `:alignment` - `:left`, `:center`, `:right`, or `:justify`
    * `:line_spacing` - line spacing multiplier (e.g. `1.5`)
    * `:space_before` - space before paragraph in points
    * `:space_after` - space after paragraph in points
    * `:bullet` - `true` for bullet, `:number` for numbered, a character string
      for custom bullet, or `false` to suppress
    * `:level` - indentation level (0-based)

  ### Fill types

    * Hex string - `"4472C4"` for solid fill
    * `{:gradient, stops, opts}` - gradient fill where stops are `[{position, color}, ...]`
      and opts include `:angle` (default `5_400_000` = 90 degrees in 60,000ths)
    * `{:pattern, preset, opts}` - pattern fill, see `Podium.Pattern` for presets;
      opts: `:foreground`, `:background` (hex color strings)
    * `{:picture, binary}` - picture fill from image binary data

  ### Line types

    * Hex string - `"000000"` for a line with default width
    * Keyword list - `[color: "000000", width: {2, :pt}, dash_style: :dash]`
    * Dash styles: `:solid`, `:dash`, `:dot`, `:dash_dot`, `:long_dash`,
      `:long_dash_dot`, `:long_dash_dot_dot`, `:sys_dot`, `:sys_dash`,
      `:sys_dash_dot`, `:sys_dash_dot_dot`
  """

  @type emu :: non_neg_integer()
  @type dimension :: emu() | {number(), :inches | :cm | :pt}
  @type hex_color :: String.t()
  @type fill ::
          hex_color()
          | {:gradient, [{non_neg_integer(), hex_color()}], keyword()}
          | {:pattern, atom(), keyword()}
          | {:picture, binary()}
          | nil
  @type line :: hex_color() | keyword() | nil
  @type alignment :: :left | :center | :right | :justify
  @type anchor :: :top | :middle | :bottom
  @type run :: String.t() | {String.t(), keyword()}
  @type paragraph :: [run()] | {[run()], keyword()}
  @type rich_text :: String.t() | [paragraph()]
  @type layout ::
          :title_slide
          | :title_content
          | :section_header
          | :two_content
          | :comparison
          | :title_only
          | :blank
          | :content_caption
          | :picture_caption
          | :title_vertical_text
          | :vertical_title_text
          | pos_integer()
  @type chart_type ::
          :column_clustered
          | :column_stacked
          | :column_stacked_100
          | :bar_clustered
          | :bar_stacked
          | :bar_stacked_100
          | :line
          | :line_markers
          | :line_stacked
          | :line_markers_stacked
          | :line_stacked_100
          | :line_markers_stacked_100
          | :pie
          | :pie_exploded
          | :area
          | :area_stacked
          | :area_stacked_100
          | :doughnut
          | :doughnut_exploded
          | :radar
          | :radar_filled
          | :radar_markers
          | :scatter
          | :scatter_lines
          | :scatter_lines_no_markers
          | :scatter_smooth
          | :scatter_smooth_no_markers
          | :bubble
          | :bubble_3d
  @type connector_type :: :straight | :elbow | :curved

  alias Podium.{Placeholder, Presentation, Slide}

  @doc """
  Creates a new presentation.

  ## Options
    * `:slide_width` - slide width, default 16:9 (12_192_000 EMU). Accepts EMU integer or `{value, unit}`.
    * `:slide_height` - slide height, default 16:9 (6_858_000 EMU). Accepts EMU integer or `{value, unit}`.
    * `:title` - document title string
    * `:author` - document author string
    * `:subject` - document subject string
    * `:keywords` - keywords string
    * `:category` - category string
    * `:comments` - comments/description string
    * `:last_modified_by` - last modified by string
    * `:created` - `DateTime` for creation timestamp
    * `:modified` - `DateTime` for modification timestamp
    * `:last_printed` - `DateTime` for last printed timestamp
    * `:revision` - revision number (integer)
    * `:content_status` - content status string
    * `:language` - language code string
    * `:version` - version string
  """
  @spec new(keyword()) :: Podium.Presentation.t()
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
  @spec add_slide(Podium.Presentation.t(), keyword()) ::
          {Podium.Presentation.t(), Podium.Slide.t()}
  def add_slide(prs, opts \\ []) do
    Presentation.add_slide(prs, opts)
  end

  @doc """
  Adds a text box to a slide.

  ## Options (required)
    * `:x` - horizontal position (EMU integer or `{value, unit}`)
    * `:y` - vertical position
    * `:width` - box width
    * `:height` - box height

  ## Options (optional)
    * `:fill` - fill color or fill tuple (see module doc)
    * `:line` - line color or line opts (see module doc)
    * `:rotation` - rotation in degrees
    * `:margin_left`, `:margin_right`, `:margin_top`, `:margin_bottom` - text margins
    * `:anchor` - vertical text anchor: `:top`, `:middle`, or `:bottom`
    * `:auto_size` - `:none`, `:text_to_fit_shape`, or `:shape_to_fit_text`
    * `:word_wrap` - `true` (default) or `false`
    * `:alignment` - default text alignment: `:left`, `:center`, `:right`, `:justify`
    * `:font_size` - default font size in points
  """
  @spec add_text_box(Podium.Slide.t(), rich_text(), keyword()) :: Podium.Slide.t()
  def add_text_box(slide, text, opts) do
    Slide.add_text_box(slide, text, opts)
  end

  @doc """
  Adds an auto shape to a slide.

  ## Parameters
    * `preset` - shape type atom (see `Podium.AutoShapeType` for all 187 presets)

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:text` - text content for the shape (string or rich text)
    * `:fill` - fill (omit to use theme default)
    * `:line` - line color or line opts
    * `:rotation` - rotation in degrees
    * `:margin_left`, `:margin_right`, `:margin_top`, `:margin_bottom` - text margins
    * `:anchor` - vertical text anchor
    * `:auto_size` - auto sizing behavior
    * `:word_wrap` - word wrap setting
    * `:alignment` - default text alignment
    * `:font_size` - default font size in points
  """
  @spec add_auto_shape(Podium.Slide.t(), atom(), keyword()) :: Podium.Slide.t()
  def add_auto_shape(slide, preset, opts) do
    Slide.add_auto_shape(slide, preset, opts)
  end

  @doc """
  Adds a connector between two points on a slide.

  ## Parameters
    * `connector_type` - `:straight`, `:elbow`, or `:curved`
    * `begin_x`, `begin_y` - start point coordinates
    * `end_x`, `end_y` - end point coordinates

  ## Options
    * `:line` - line color string or keyword list with `:color`, `:width`, `:dash_style`
  """
  @spec add_connector(
          Podium.Slide.t(),
          connector_type(),
          dimension(),
          dimension(),
          dimension(),
          dimension(),
          keyword()
        ) :: Podium.Slide.t()
  def add_connector(slide, connector_type, begin_x, begin_y, end_x, end_y, opts \\ []) do
    Slide.add_connector(slide, connector_type, begin_x, begin_y, end_x, end_y, opts)
  end

  @doc """
  Adds a chart to a slide. Returns `{presentation, slide}`.

  ## Parameters
    * `chart_type` - chart type atom (see `Podium.Chart.ChartType` for all types)
    * `chart_data` - `Podium.Chart.ChartData`, `Podium.Chart.XyChartData`, or
      `Podium.Chart.BubbleChartData` struct

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:title` - chart title as string, or keyword list with `:text`, `:font_size`,
      `:bold`, `:italic`, `:color`, `:font`
    * `:legend` - legend position atom (`:left`, `:right`, `:top`, `:bottom`) or `false`
      to hide, or keyword list with `:position`, `:font_size`, `:bold`, `:italic`,
      `:color`, `:font`
    * `:data_labels` - list of atoms to show (`:value`, `:category`, `:series`, `:percent`)
      or keyword list with `:show` (list), `:position` (`:center`, `:inside_end`,
      `:inside_base`, `:outside_end`, `:top`, `:bottom`, `:left`, `:right`, `:best_fit`),
      `:number_format` (Excel format string)
    * `:category_axis` - keyword list with `:title`, `:type` (`:date` for date axis),
      `:number_format`, `:major_gridlines`, `:minor_gridlines`, `:visible`, `:reverse`,
      `:crosses`, `:label_rotation`, `:major_tick_mark`, `:minor_tick_mark`,
      `:base_time_unit`, `:major_time_unit`, `:minor_time_unit`, `:major_unit`, `:minor_unit`
    * `:value_axis` - keyword list with `:title`, `:number_format`, `:major_gridlines`,
      `:minor_gridlines`, `:min`, `:max`, `:major_unit`, `:minor_unit`, `:visible`,
      `:reverse`, `:crosses`, `:label_rotation`, `:major_tick_mark`, `:minor_tick_mark`
  """
  @spec add_chart(
          Podium.Presentation.t(),
          Podium.Slide.t(),
          chart_type(),
          Podium.Chart.ChartData.t()
          | Podium.Chart.XyChartData.t()
          | Podium.Chart.BubbleChartData.t(),
          keyword()
        ) :: {Podium.Presentation.t(), Podium.Slide.t()}
  def add_chart(prs, slide, chart_type, chart_data, opts) do
    Presentation.add_chart(prs, slide, chart_type, chart_data, opts)
  end

  @doc """
  Adds a combo chart (multiple chart types in one plot area) to a slide.
  Returns `{presentation, slide}`.

  ## Parameters
    * `chart_data` - `%ChartData{}` with shared categories and series
    * `plots` - list of `{chart_type, opts}` tuples where opts are:
      * `:series` - list of zero-based series indices to include in this plot
      * `:secondary_axis` - `true` to plot on secondary value axis (default `false`)

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:title` - chart title (string or keyword list)
    * `:legend` - legend position or keyword list
    * `:data_labels` - data label configuration
    * `:category_axis` - category axis options
    * `:value_axis` - primary value axis options
    * `:secondary_value_axis` - secondary value axis options (same keys as `:value_axis`)
  """
  @spec add_combo_chart(
          Podium.Presentation.t(),
          Podium.Slide.t(),
          Podium.Chart.ChartData.t(),
          [{chart_type(), keyword()}],
          keyword()
        ) :: {Podium.Presentation.t(), Podium.Slide.t()}
  def add_combo_chart(prs, slide, chart_data, plots, opts) do
    Presentation.add_combo_chart(prs, slide, chart_data, plots, opts)
  end

  @doc """
  Adds an image to a slide. Returns `{presentation, slide}`.

  Image format is auto-detected from magic bytes. Supported formats:
  PNG, JPEG, BMP, GIF, TIFF, EMF, WMF.

  ## Options (required)
    * `:x` - horizontal position
    * `:y` - vertical position

  ## Options (optional)
    * `:width` - image width (auto-calculated from native size if only `:height` given or neither given)
    * `:height` - image height (auto-calculated from native size if only `:width` given or neither given)
    * `:crop` - keyword list with `:left`, `:top`, `:right`, `:bottom` (values in 1/1000ths of a percent)
    * `:rotation` - rotation in degrees
    * `:shape` - clip shape preset: `:ellipse`, `:diamond`, `:round_rect`, `:star5`,
      `:star6`, `:star8`, `:heart`, `:triangle`, `:hexagon`, `:octagon`, or a preset
      geometry string (default `"rect"`)
  """
  @spec add_image(Podium.Presentation.t(), Podium.Slide.t(), binary(), keyword()) ::
          {Podium.Presentation.t(), Podium.Slide.t()}
  def add_image(prs, slide, binary, opts) do
    Presentation.add_image(prs, slide, binary, opts)
  end

  @doc """
  Adds a text box with a picture (blip) fill to a slide. Returns `{presentation, slide}`.

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:fill_mode` - `:stretch` (default) or `:tile`
    * All other text box options (`:rotation`, `:margin_*`, `:anchor`, etc.)
  """
  @spec add_picture_fill_text_box(
          Podium.Presentation.t(),
          Podium.Slide.t(),
          rich_text(),
          binary(),
          keyword()
        ) :: {Podium.Presentation.t(), Podium.Slide.t()}
  def add_picture_fill_text_box(prs, slide, text, image_binary, opts) do
    Presentation.add_picture_fill_text_box(prs, slide, text, image_binary, opts)
  end

  @doc """
  Adds a freeform shape (built with `Podium.Freeform`) to a slide.

  ## Options
    * `:origin_x`, `:origin_y` - offset for the shape's bounding box origin
    * `:fill` - fill color or fill tuple
    * `:line` - line color or line opts
    * `:rotation` - rotation in degrees
  """
  @spec add_freeform(Podium.Freeform.t(), Podium.Slide.t(), keyword()) :: Podium.Slide.t()
  def add_freeform(%Podium.Freeform{} = fb, slide, opts \\ []) do
    Slide.add_freeform(slide, fb, opts)
  end

  @doc """
  Adds a video (movie) to a slide. Returns `{presentation, slide}`.

  All position/size options are required (no auto-scaling for video).

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:mime_type` - MIME type string (default `"video/unknown"`)
    * `:poster_frame` - poster frame image binary (default: 1x1 transparent PNG)
  """
  @spec add_movie(Podium.Presentation.t(), Podium.Slide.t(), binary(), keyword()) ::
          {Podium.Presentation.t(), Podium.Slide.t()}
  def add_movie(prs, slide, binary, opts) do
    Presentation.add_movie(prs, slide, binary, opts)
  end

  @doc """
  Adds a table to a slide.

  `rows` is a list of lists where each inner list is a row of cell values.
  Cell values can be:
    * Plain string - `"text"`
    * Rich text list - `[{"bold", bold: true}]`
    * Cell tuple with options - `{"text", col_span: 2, fill: "FF0000"}`
    * `:merge` atom for cells covered by a span

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:col_widths` - list of column widths (auto-calculated if omitted)
    * `:row_heights` - list of row heights (auto-calculated if omitted)
    * `:table_style` - keyword list of style booleans:
      * `:first_row` - highlight first row (default `true`)
      * `:last_row` - highlight last row (default `false`)
      * `:first_col` - highlight first column (default `false`)
      * `:last_col` - highlight last column (default `false`)
      * `:band_row` - alternating row bands (default `true`)
      * `:band_col` - alternating column bands (default `false`)

  ## Cell options

    * `:col_span` - number of columns to span
    * `:row_span` - number of rows to span
    * `:fill` - cell fill color or fill tuple
    * `:borders` - `[left: color_or_opts, right: ..., top: ..., bottom: ...]`
    * `:padding` - `[left: dim, right: dim, top: dim, bottom: dim]`
    * `:anchor` - vertical text alignment: `:top`, `:middle`, `:bottom`
  """
  @spec add_table(Podium.Slide.t(), [[term()]], keyword()) :: Podium.Slide.t()
  def add_table(slide, rows, opts) do
    Slide.add_table(slide, rows, opts)
  end

  @doc """
  Sets a placeholder's text content on a slide.

  The slide must have been created with a layout that has the given placeholder.
  """
  @spec set_placeholder(Podium.Slide.t(), atom(), rich_text()) :: Podium.Slide.t()
  def set_placeholder(slide, name, text) do
    layout = layout_atom(slide.layout_index)
    ph = Placeholder.new(layout, name, text)
    %{slide | placeholders: slide.placeholders ++ [ph]}
  end

  @doc """
  Sets a picture placeholder on a slide. Returns `{presentation, slide}`.

  Only works on layouts with picture placeholders (e.g. `:picture_caption`).
  """
  @spec set_picture_placeholder(Podium.Presentation.t(), Podium.Slide.t(), atom(), binary()) ::
          {Podium.Presentation.t(), Podium.Slide.t()}
  def set_picture_placeholder(prs, slide, name, binary) do
    Presentation.set_picture_placeholder(prs, slide, name, binary)
  end

  @doc """
  Places a chart into a content placeholder. Returns `{presentation, slide}`.

  The placeholder must be a content placeholder (type: nil) — e.g. `:content` on
  `:title_content`, or `:left_content`/`:right_content` on `:two_content`.
  Position and size are inherited from the template layout.
  """
  @spec set_chart_placeholder(
          Podium.Presentation.t(),
          Podium.Slide.t(),
          atom(),
          chart_type(),
          Podium.Chart.ChartData.t(),
          keyword()
        ) :: {Podium.Presentation.t(), Podium.Slide.t()}
  def set_chart_placeholder(prs, slide, name, chart_type, chart_data, opts \\ []) do
    Presentation.set_chart_placeholder(prs, slide, name, chart_type, chart_data, opts)
  end

  @doc """
  Places a table into a content placeholder. Returns `{presentation, slide}`.

  The placeholder must be a content placeholder (type: nil).
  Position and size are inherited from the template layout.
  """
  @spec set_table_placeholder(
          Podium.Presentation.t(),
          Podium.Slide.t(),
          atom(),
          [[term()]],
          keyword()
        ) :: {Podium.Presentation.t(), Podium.Slide.t()}
  def set_table_placeholder(prs, slide, name, rows, opts \\ []) do
    Presentation.set_table_placeholder(prs, slide, name, rows, opts)
  end

  @doc """
  Sets presentation-level footer, date, and slide number.

  ## Options
    * `:footer` - footer text string
    * `:date` - date text string
    * `:slide_number` - boolean, whether to show slide numbers
  """
  @spec set_footer(Podium.Presentation.t(), keyword()) :: Podium.Presentation.t()
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
  Sets speaker notes on a slide.
  """
  @spec set_notes(Podium.Slide.t(), String.t()) :: Podium.Slide.t()
  def set_notes(slide, text) do
    Presentation.set_notes(slide, text)
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
    * `:created` - creation timestamp (`DateTime`)
    * `:modified` - modification timestamp (`DateTime`)
    * `:last_printed` - last printed timestamp (`DateTime`)
    * `:revision` - revision number (integer)
    * `:content_status` - content status string
    * `:language` - language code string
    * `:version` - version string
  """
  @spec set_core_properties(Podium.Presentation.t(), keyword()) :: Podium.Presentation.t()
  def set_core_properties(prs, opts) do
    Presentation.set_core_properties(prs, opts)
  end

  @doc """
  Replaces a slide in the presentation with an updated version.
  """
  @spec put_slide(Podium.Presentation.t(), Podium.Slide.t()) :: Podium.Presentation.t()
  def put_slide(prs, slide) do
    Presentation.put_slide(prs, slide)
  end

  @doc """
  Saves the presentation to a file.
  """
  @spec save(Podium.Presentation.t(), String.t()) :: :ok | {:error, term()}
  def save(prs, path) do
    Presentation.save(prs, path)
  end

  @doc """
  Saves the presentation to an in-memory binary.
  """
  @spec save_to_memory(Podium.Presentation.t()) :: {:ok, binary()} | {:error, term()}
  def save_to_memory(prs) do
    Presentation.save_to_memory(prs)
  end
end
