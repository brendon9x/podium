defmodule Podium do
  @moduledoc """
  Elixir library for generating PowerPoint (.pptx) files with editable charts.

  Podium provides a pipe-friendly API for building presentations programmatically.
  Create slides independently with `Podium.Slide.new/1`, populate them with
  content using `add_chart/4`, `add_image/3`, `add_text_box/3`, etc., then
  add them to a presentation with `add_slide/2` and save.

  ## Example

      alias Podium.Chart.ChartData

      data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3"])
        |> ChartData.add_series("Revenue", [100, 200, 300])

      slide =
        Podium.Slide.new(:title_content)
        |> Podium.add_chart(:column_clustered, data, x: {1, :inches}, y: {2, :inches}, width: {8, :inches}, height: {4, :inches})
        |> Podium.add_text_box("Hello", x: {1, :inches}, y: {6, :inches}, width: {4, :inches}, height: {1, :inches})

      Podium.new()
      |> Podium.add_slide(slide)
      |> Podium.save("output.pptx")

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
    * `{:picture, binary}` - picture fill from image binary data (shapes only)
    * `:none` - no fill

  ### Line types

    * Hex string - `"000000"` for a line with default width
    * Keyword list - `[color: "000000", width: {2, :pt}, dash_style: :dash]`. `:color`
      may be `:none`, `:fill` takes any fill type in its place, and a list with only
      `:width` or `:dash_style` keeps the default colour
    * `:none` - no line
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
          | :none
          | nil
  @type line :: hex_color() | keyword() | :none | nil
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

  alias Podium.{Presentation, Slide, Units}

  @doc """
  Creates a new presentation from the bundled template.

  Use `from_template/2` to build on a template of your own.

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
  Creates a new presentation from your own template package.

  `source` is either a path to a `.pptx`/`.potx` file or the bytes of one. The
  template keeps everything it declares: masters, layouts, themes, media, notes
  master, default text style and notes size. Podium adds slides to it.

  ## Template requirements

    * `ppt/presentation.xml`, `ppt/_rels/presentation.xml.rels` and
      `[Content_Types].xml` must be present, as they are in any package saved by
      PowerPoint, Keynote or Google Slides.
    * The template must contain no slides. Slide masters, layouts and a notes
      master are what a template is for; existing slides would collide with the
      ones Podium writes.
    * The template must relate to at least one slide master, or its layouts
      have nothing for slides to sit on.
    * To set core properties, the template's `_rels/.rels` must already relate
      to `docProps/core.xml`. A package saved by PowerPoint always does.

  ## Differences from `new/1`

    * Slide size comes from the template, so `:slide_width` and `:slide_height`
      are ignored. Layout and master coordinates are never scaled.
    * Placeholders are addressed by the `{type, idx}` pair
      `Podium.Template.inspect/1` reports, not by the bundled template's names.
      `set_placeholder/3`, `set_picture_placeholder/3`,
      `set_chart_placeholder/6` and `set_table_placeholder/5` all take a pair;
      the last two take the layout placeholder's box as the chart's or table's
      position and size. Passing a name raises.

  Core-property options are the same as `new/1`.

  ## Example

      Podium.from_template("priv/brand/skeleton.pptx", title: "Q3 review")
      |> Podium.add_slide(slide)
      |> Podium.save("q3.pptx")
  """
  @spec from_template(binary(), keyword()) :: Podium.Presentation.t()
  def from_template(source, opts \\ []) do
    Presentation.from_template(source, opts)
  end

  @doc """
  Adds a slide to the presentation. Returns the updated presentation.

  Slides are created independently with `Podium.Slide.new/1`, populated
  with content, then added to the presentation.

  ## Example

      slide = Podium.Slide.new(:title_content)
      prs = Podium.add_slide(prs, slide)
  """
  @spec add_slide(Podium.Presentation.t(), Podium.Slide.t()) :: Podium.Presentation.t()
  def add_slide(prs, slide) do
    Presentation.add_slide(prs, slide)
  end

  @doc """
  Returns the x position that centres something `width` wide on the
  presentation's slides, in EMU.

  It reads the presentation's own slide width, so it holds for 16:9, 4:3, a
  custom `:slide_width` or a template's size. Pass the result as `:x`; for a
  row of shapes, centre the row's total width and step from there.

  ## Example

      prs = Podium.new()

      Podium.add_chart(slide, :column_clustered, data,
        x: Podium.center_x(prs, {12, :inches}),
        y: {1, :inches},
        width: {12, :inches},
        height: {5, :inches})
  """
  @spec center_x(Podium.Presentation.t(), dimension()) :: integer()
  def center_x(%Presentation{slide_width: slide_width}, width) do
    div(slide_width - Units.to_emu(width), 2)
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
  Adds a chart to a slide. Returns the updated slide.

  ## Parameters
    * `chart_type` - chart type atom (see `Podium.Chart.ChartType` for all types)
    * `chart_data` - `Podium.Chart.ChartData`, `Podium.Chart.XyChartData`, or
      `Podium.Chart.BubbleChartData` struct

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  On scatter and bubble charts `:category_axis` sets the horizontal (X) value axis
  and `:value_axis` the vertical (Y) one; both take the value axis options.

  ## Fill and line

  The chart and plot areas, titles, the legend, axes, gridlines and data labels
  take `:fill` and `:line` in the forms listed under "Fill types" and "Line types"
  in the module docs, including `:none`.

  ## Font options

  Every piece of chart text takes the font options of a text run: `:font_size`,
  `:bold`, `:italic`, `:underline`, `:strikethrough`, `:superscript`, `:subscript`,
  `:color`, `:font` and `:lang`. `bold: false` and `italic: false` turn off what
  `:text` or the template turns on.

  ## Options (optional)
    * `:text` - font options for all chart text. Each element below overrides them.
      Chart text is 18pt unless this gives another `:font_size`; titles take every
      option but the size
    * `:title` - chart title as a string, rich text (a list of paragraphs, as for
      `add_text_box/3`), or keyword list with `:text` (either form), `:fill`, `:line`,
      font options that apply to every run, a manual position `:x`, `:y` (fractions
      of the chart frame) and `:overlay`
    * `:legend` - legend position atom (`:left`, `:right`, `:top`, `:bottom`) or `false`
      to hide, or keyword list with `:position` (default `:right`), a manual position
      `:x`, `:y` and optional `:w`, `:h` (fractions of the chart frame), `:overlay`,
      `:fill`, `:line` and font options
    * `:data_labels` - list of atoms to show (`:value`, `:category`, `:series`, `:percent`,
      `:legend_key`, `:bubble_size`) or keyword list with `:show` (list, default
      `[:value]`), `:position` (`:center`, `:inside_end`, `:inside_base`, `:outside_end`,
      `:top`, `:bottom`, `:left`, `:right`, `:best_fit`; each chart type accepts some of
      these and raises on others), `:number_format` (Excel format string), `:separator`,
      `:fill`, `:line` and font options. Series take the same options for their own
      labels through `Podium.Chart.ChartData.add_series/4`
    * `:background` - chart area: `:none` for transparent with no border, a fill, or a
      keyword list with `:fill` and `:line`
    * `:gap_width` - bar and column charts: space between bar groups as a percentage
      of bar width, 0..500
    * `:overlap` - bar and column charts: how far bars in a group overlap, -100..100.
      Replaces the chart type's own
    * `:vary_by_categories` - colour each category differently (on by default for pie
      and doughnut only)
    * `:bubble_scale` - bubble charts: bubble size as a percentage of the default, 0..300
    * `:plot_area` - keyword list with `:fill` and `:line` for the plot area, and a
      manual position `:x`, `:y`, `:w`, `:h` (fractions of the chart frame, all four
      together) with `:target` (`:inner`, the default, or `:outer`)
    * `:category_axis` - keyword list with `:title` (same forms as the chart `:title`),
      `:type` (`:date` for date axis),
      `:number_format`, `:major_gridlines`, `:minor_gridlines`, `:visible`, `:reverse`,
      `:crosses`, `:label_rotation`, `:tick_label_position` (`:next_to`, `:low`, `:high`,
      `:none`), `:label_offset` (0..1000), `:major_tick_mark`, `:minor_tick_mark`,
      `:base_time_unit`, `:major_time_unit`, `:minor_time_unit`, `:major_unit`, `:minor_unit`,
      `:line` (the axis line), and font options for the tick labels. Gridlines are off
      by default; `true` turns them on and `[line: ...]` formats them
    * `:value_axis` - keyword list with `:title`, `:number_format`, `:major_gridlines`,
      `:minor_gridlines`, `:min`, `:max`, `:major_unit`, `:minor_unit`, `:visible`,
      `:reverse`, `:crosses`, `:label_rotation`, `:tick_label_position`, `:major_tick_mark`,
      `:minor_tick_mark`, `:line` (the axis line), and font options for the tick labels.
      Major gridlines are on by default; `false` turns them off and `[line: ...]`
      formats them
  """
  @spec add_chart(
          Podium.Slide.t(),
          chart_type(),
          Podium.Chart.ChartData.t()
          | Podium.Chart.XyChartData.t()
          | Podium.Chart.BubbleChartData.t(),
          keyword()
        ) :: Podium.Slide.t()
  def add_chart(slide, chart_type, chart_data, opts) do
    Slide.add_chart(slide, chart_type, chart_data, opts)
  end

  @doc """
  Adds a combo chart (multiple chart types in one plot area) to a slide.
  Returns the updated slide.

  ## Parameters
    * `chart_data` - `%ChartData{}` with shared categories and series
    * `plots` - list of `{chart_type, opts}` tuples where opts are:
      * `:series` - list of zero-based series indices to include in this plot
      * `:secondary_axis` - `true` to plot on secondary value axis (default `false`)
      * `:gap_width`, `:overlap` - bar plots only, as in `add_chart/4`
      * `:vary_by_categories` - as in `add_chart/4`
      * `:data_labels` - labels for this plot, as in `add_chart/4`; `[]` turns them off

      A plot without its own value for these takes the chart-level option.

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:title` - chart title (string or keyword list)
    * `:legend` - legend position or keyword list
    * `:data_labels` - data label configuration
    * `:text` - font options for all chart text
    * `:background` - chart area fill and line
    * `:plot_area` - plot area fill, line and manual position
    * `:gap_width`, `:overlap`, `:vary_by_categories` - defaults for every plot
    * `:category_axis` - category axis options
    * `:value_axis` - primary value axis options
    * `:secondary_value_axis` - secondary value axis options (same keys as `:value_axis`)

  Each option takes the same shape as in `add_chart/4`, including the font options.
  """
  @spec add_combo_chart(
          Podium.Slide.t(),
          Podium.Chart.ChartData.t(),
          [{chart_type(), keyword()}],
          keyword()
        ) :: Podium.Slide.t()
  def add_combo_chart(slide, chart_data, plots, opts) do
    Slide.add_combo_chart(slide, chart_data, plots, opts)
  end

  @doc """
  Adds an image to a slide. Returns the updated slide.

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
  @spec add_image(Podium.Slide.t(), binary(), keyword()) :: Podium.Slide.t()
  def add_image(slide, binary, opts) do
    Slide.add_image(slide, binary, opts)
  end

  @doc """
  Adds a text box with a picture (blip) fill to a slide. Returns the updated slide.

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:fill_mode` - `:stretch` (default) or `:tile`
    * All other text box options (`:rotation`, `:margin_*`, `:anchor`, etc.)
  """
  @spec add_picture_fill_text_box(
          Podium.Slide.t(),
          rich_text(),
          binary(),
          keyword()
        ) :: Podium.Slide.t()
  def add_picture_fill_text_box(slide, text, image_binary, opts) do
    Slide.add_picture_fill_text_box(slide, text, image_binary, opts)
  end

  @doc """
  Adds a freeform shape (built with `Podium.Freeform`) to a slide.

  ## Options
    * `:origin_x`, `:origin_y` - offset for the shape's bounding box origin
    * `:fill` - fill color or fill tuple
    * `:line` - line color or line opts
    * `:rotation` - rotation in degrees
  """
  @spec add_freeform(Podium.Slide.t(), Podium.Freeform.t(), keyword()) :: Podium.Slide.t()
  def add_freeform(slide, %Podium.Freeform{} = fb, opts \\ []) do
    Slide.add_freeform(slide, fb, opts)
  end

  @doc """
  Adds a video (movie) to a slide. Returns the updated slide.

  All position/size options are required (no auto-scaling for video).

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:mime_type` - MIME type string (default `"video/unknown"`)
    * `:poster_frame` - poster frame image binary (default: 1x1 transparent PNG)
  """
  @spec add_movie(Podium.Slide.t(), binary(), keyword()) :: Podium.Slide.t()
  def add_movie(slide, binary, opts) do
    Slide.add_video(slide, binary, opts)
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

  ## Available placeholders by layout

  | Layout | Placeholders |
  |--------|-------------|
  | `:title_slide` | `:title`, `:subtitle` |
  | `:title_content` | `:title`, `:content` |
  | `:section_header` | `:title`, `:body` |
  | `:two_content` | `:title`, `:left_content`, `:right_content` |
  | `:comparison` | `:title`, `:left_heading`, `:left_content`, `:right_heading`, `:right_content` |
  | `:title_only` | `:title` |
  | `:blank` | (none) |
  | `:content_caption` | `:title`, `:content`, `:caption` |
  | `:picture_caption` | `:title`, `:caption` (use `set_picture_placeholder/3` for `:picture`) |
  | `:title_vertical_text` | `:title`, `:body` |
  | `:vertical_title_text` | `:title`, `:body` |

  ## By type and idx

  On a presentation built with `from_template/2`, address the placeholder by the
  `{type, idx}` pair `Podium.Template.inspect/1` reports for it:

      Podium.set_placeholder(slide, {"title", 0}, "Category performance")
      Podium.set_placeholder(slide, {"obj", 14}, "Volume grew 4.2%")

  The type is always the layout placeholder's own, so a content placeholder is
  `{"obj", idx}` even when it holds a picture or a chart.
  """
  @spec set_placeholder(
          Podium.Slide.t(),
          atom() | {String.t(), non_neg_integer()},
          rich_text()
        ) :: Podium.Slide.t()
  def set_placeholder(slide, name, text) when is_atom(name) do
    layout = Slide.layout_atom(slide.layout_index)
    ph = Podium.Placeholder.new(layout, name, text)
    %{slide | placeholders: slide.placeholders ++ [ph]}
  end

  def set_placeholder(slide, {type, idx}, text) when is_binary(type) and is_integer(idx) do
    ph = Podium.Placeholder.new({type, idx}, text)
    %{slide | placeholders: slide.placeholders ++ [ph]}
  end

  @doc """
  Sets a picture placeholder on a slide. Returns the updated slide.

  With a bundled-template name, this only works on layouts that have a picture
  placeholder (e.g. `:picture_caption`). A `{type, idx}` pair from
  `Podium.Template.inspect/1` works on any template, including dropping a
  picture into a content placeholder such as `{"obj", 14}`.
  """
  @spec set_picture_placeholder(
          Podium.Slide.t(),
          atom() | {String.t(), non_neg_integer()},
          binary()
        ) :: Podium.Slide.t()
  def set_picture_placeholder(slide, name, binary) do
    Slide.set_picture_placeholder(slide, name, binary)
  end

  @doc """
  Places a chart into a content placeholder. Returns the updated slide.

  Addressed by a bundled-template name, the placeholder must be a content
  placeholder (type: nil) — e.g. `:content` on `:title_content`, or
  `:left_content`/`:right_content` on `:two_content`. Addressed by the
  `{type, idx}` pair `Podium.Template.inspect/1` reports, it works on any
  template. Position and size are taken from the layout.
  """
  @spec set_chart_placeholder(
          Podium.Presentation.t(),
          Podium.Slide.t(),
          atom() | {String.t(), non_neg_integer()},
          chart_type(),
          Podium.Chart.ChartData.t(),
          keyword()
        ) :: Podium.Slide.t()
  def set_chart_placeholder(prs, slide, name, chart_type, chart_data, opts \\ []) do
    Presentation.set_chart_placeholder(prs, slide, name, chart_type, chart_data, opts)
  end

  @doc """
  Places a table into a content placeholder. Returns the updated slide.

  Addressed by a bundled-template name, the placeholder must be a content
  placeholder (type: nil). Addressed by the `{type, idx}` pair
  `Podium.Template.inspect/1` reports, it works on any template. Position and
  size are taken from the layout.
  """
  @spec set_table_placeholder(
          Podium.Presentation.t(),
          Podium.Slide.t(),
          atom() | {String.t(), non_neg_integer()},
          [[term()]],
          keyword()
        ) :: Podium.Slide.t()
  def set_table_placeholder(prs, slide, name, rows, opts \\ []) do
    Presentation.set_table_placeholder(prs, slide, name, rows, opts)
  end

  @doc """
  Sets presentation-level footer, date, and slide number.

  Each is emitted on a slide only when the slide's layout defines the matching
  placeholder, and at the idx that layout uses.

  ## Options
    * `:footer` - footer text string
    * `:date` - date text string
    * `:slide_number` - boolean, whether to show slide numbers
  """
  @spec set_footer(Podium.Presentation.t(), keyword()) :: Podium.Presentation.t()
  def set_footer(prs, opts) do
    Presentation.set_footer(prs, opts)
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
  Replaces a slide in the presentation with an updated version (matched by ref).
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
