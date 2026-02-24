defmodule Podium.Slide do
  @moduledoc """
  Represents a single slide in a presentation.

  Slides are created independently with `new/1` or `new/2`, then populated
  with content using pipe-friendly functions, and finally added to a
  presentation with `Podium.add_slide/2`.

  ## Example

      slide =
        Podium.Slide.new(:title_content)
        |> Podium.add_chart(:bar, data, x: {1, :in}, y: {2, :in}, width: {8, :in}, height: {4, :in})
        |> Podium.add_image(png, x: {1, :in}, y: {1, :in})
        |> Podium.add_text_box("Hello", x: {1, :in}, y: {6, :in}, width: {4, :in}, height: {1, :in})

      prs
      |> Podium.add_slide(slide)
      |> Podium.save("output.pptx")
  """

  alias Podium.Chart
  alias Podium.Chart.ComboChart
  alias Podium.OPC.Constants
  alias Podium.{Connector, Drawing, Image, Shape, Table, Units, Video}

  @blank_layout_index 7
  @default_slide_width 12_192_000
  @default_slide_height 6_858_000

  defstruct [
    :index,
    :layout_index,
    :pres_rid,
    ref: nil,
    background: nil,
    background_image: nil,
    notes_text: nil,
    shapes: [],
    charts: [],
    images: [],
    tables: [],
    connectors: [],
    videos: [],
    placeholders: [],
    picture_placeholders: [],
    fill_images: [],
    next_shape_id: 2,
    slide_width: @default_slide_width,
    slide_height: @default_slide_height
  ]

  @type t :: %__MODULE__{
          index: pos_integer() | nil,
          layout_index: pos_integer() | nil,
          pres_rid: String.t() | nil,
          ref: reference() | nil,
          background: term(),
          background_image: {binary(), String.t()} | nil,
          notes_text: String.t() | nil,
          shapes: [Podium.Shape.t()],
          charts: [Podium.Chart.t()],
          images: [Podium.Image.t()],
          tables: [Podium.Table.t()],
          connectors: [Podium.Connector.t()],
          videos: [Podium.Video.t()],
          placeholders: [Podium.Placeholder.t()],
          picture_placeholders: [tuple()],
          fill_images: [{pos_integer(), binary(), String.t()}],
          next_shape_id: pos_integer(),
          slide_width: non_neg_integer(),
          slide_height: non_neg_integer()
        }

  @doc """
  Creates a new slide with the given layout.

  The first argument is a layout atom or integer index. Options can set
  the slide background and notes.

  ## Options
    * `:background` - background fill (hex color, gradient tuple, pattern tuple,
      or `{:picture, binary}`)
    * `:notes` - speaker notes text
    * `:slide_width` - slide width for percent resolution (default 12,192,000 EMU / 16:9)
    * `:slide_height` - slide height for percent resolution (default 6,858,000 EMU / 16:9)

  ## Available layouts
    * `:title_slide` (1), `:title_content` (2), `:section_header` (3),
      `:two_content` (4), `:comparison` (5), `:title_only` (6),
      `:blank` (7), `:content_caption` (8), `:picture_caption` (9),
      `:title_vertical_text` (10), `:vertical_title_text` (11)
  """
  @spec new(Podium.layout(), keyword()) :: t()
  def new(layout \\ :blank, opts \\ [])

  def new(layout, opts) when is_atom(layout) or is_integer(layout) do
    layout_index = resolve_layout_index(layout)
    background = Keyword.get(opts, :background)

    {background, background_image} =
      case background do
        {:picture, binary} when is_binary(binary) ->
          ext = detect_fill_extension(binary)
          {{:picture, binary}, {binary, ext}}

        other ->
          {other, nil}
      end

    slide_width = Units.to_emu(Keyword.get(opts, :slide_width, @default_slide_width))
    slide_height = Units.to_emu(Keyword.get(opts, :slide_height, @default_slide_height))

    %__MODULE__{
      ref: make_ref(),
      index: nil,
      layout_index: layout_index,
      background: background,
      background_image: background_image,
      notes_text: Keyword.get(opts, :notes),
      slide_width: slide_width,
      slide_height: slide_height
    }
  end

  @doc """
  Returns the partname for this slide within the package.
  """
  @spec partname(t()) :: String.t()
  def partname(%__MODULE__{index: index}), do: "ppt/slides/slide#{index}.xml"

  @doc """
  Returns the rels partname for this slide.
  """
  @spec rels_partname(t()) :: String.t()
  def rels_partname(%__MODULE__{index: index}),
    do: "ppt/slides/_rels/slide#{index}.xml.rels"

  @doc """
  Adds a text box shape to the slide.
  """
  @spec add_text_box(t(), Podium.rich_text(), keyword()) :: t()
  def add_text_box(%__MODULE__{} = slide, text, opts) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    shape = Shape.text_box(slide.next_shape_id, text, opts)

    %{slide | shapes: slide.shapes ++ [shape], next_shape_id: slide.next_shape_id + 1}
  end

  @doc """
  Adds an auto shape to the slide.
  """
  @spec add_auto_shape(t(), atom(), keyword()) :: t()
  def add_auto_shape(%__MODULE__{} = slide, preset, opts) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    shape = Shape.auto_shape(slide.next_shape_id, preset, opts)

    %{slide | shapes: slide.shapes ++ [shape], next_shape_id: slide.next_shape_id + 1}
  end

  @doc """
  Adds a connector to the slide.
  """
  @spec add_connector(
          t(),
          Podium.connector_type(),
          Podium.dimension(),
          Podium.dimension(),
          Podium.dimension(),
          Podium.dimension(),
          keyword()
        ) ::
          t()
  def add_connector(%__MODULE__{} = slide, connector_type, begin_x, begin_y, end_x, end_y, opts) do
    begin_x = maybe_resolve_percent(begin_x, slide.slide_width)
    begin_y = maybe_resolve_percent(begin_y, slide.slide_height)
    end_x = maybe_resolve_percent(end_x, slide.slide_width)
    end_y = maybe_resolve_percent(end_y, slide.slide_height)

    conn =
      Connector.new(slide.next_shape_id, connector_type, begin_x, begin_y, end_x, end_y, opts)

    %{
      slide
      | connectors: slide.connectors ++ [conn],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Adds a text box with a picture fill. The image binary is stored for packaging.
  """
  @spec add_picture_fill_text_box(t(), Podium.rich_text(), binary(), keyword()) :: t()
  def add_picture_fill_text_box(%__MODULE__{} = slide, text, image_binary, opts) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    extension = detect_fill_extension(image_binary)
    fill_mode = Keyword.get(opts, :fill_mode, :stretch)

    # Create the shape with a placeholder fill marker
    shape_id = slide.next_shape_id
    fill_index = length(slide.fill_images)
    shape_opts = Keyword.put(opts, :fill, {:picture_fill, fill_index})

    shape = Shape.text_box(shape_id, text, shape_opts)
    shape = %{shape | fill_opts: [mode: fill_mode]}

    fill_entry = {shape_id, image_binary, extension}

    %{
      slide
      | shapes: slide.shapes ++ [shape],
        fill_images: slide.fill_images ++ [fill_entry],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Adds a chart to the slide.
  """
  @spec add_chart(t(), atom(), struct(), keyword()) :: t()
  def add_chart(%__MODULE__{} = slide, chart_type, chart_data, opts) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    chart = Chart.new(chart_type, chart_data, opts)

    %{
      slide
      | charts: slide.charts ++ [chart],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Adds a combo chart to the slide.
  """
  @spec add_combo_chart(t(), Podium.Chart.ChartData.t(), [{atom(), keyword()}], keyword()) :: t()
  def add_combo_chart(%__MODULE__{} = slide, chart_data, plot_specs, opts) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    combo = ComboChart.new(chart_data, plot_specs)
    chart = Chart.new_combo(combo, opts)

    %{
      slide
      | charts: slide.charts ++ [chart],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Adds an image to the slide.
  """
  @spec add_image(t(), binary(), keyword()) :: t()
  def add_image(%__MODULE__{} = slide, binary, opts) when is_binary(binary) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    image = Image.new(binary, opts)

    %{
      slide
      | images: slide.images ++ [image],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Adds a video to the slide.
  """
  @spec add_video(t(), binary(), keyword()) :: t()
  def add_video(%__MODULE__{} = slide, binary, opts) when is_binary(binary) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    video = Video.new(binary, opts)

    %{
      slide
      | videos: slide.videos ++ [video],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Sets a picture placeholder on the slide. Stores the placeholder, binary,
  and extension for later index assignment during serialization.
  """
  @spec set_picture_placeholder(t(), atom(), binary()) :: t()
  def set_picture_placeholder(%__MODULE__{} = slide, name, binary)
      when is_atom(name) and is_binary(binary) do
    layout_atom = layout_atom(slide.layout_index)
    ph = Podium.Placeholder.new_picture(layout_atom, name)
    extension = detect_fill_extension(binary)

    picture_entry = {ph, binary, extension}
    %{slide | picture_placeholders: slide.picture_placeholders ++ [picture_entry]}
  end

  @doc """
  Adds a freeform shape to the slide.
  """
  @spec add_freeform(t(), Podium.Freeform.t(), keyword()) :: t()
  def add_freeform(%__MODULE__{} = slide, %Podium.Freeform{} = fb, opts \\ []) do
    shape = Shape.freeform(slide.next_shape_id, fb, opts)
    %{slide | shapes: slide.shapes ++ [shape], next_shape_id: slide.next_shape_id + 1}
  end

  @doc """
  Adds a table to the slide.
  """
  @spec add_table(t(), [[term()]], keyword()) :: t()
  def add_table(%__MODULE__{} = slide, rows, opts) do
    opts = resolve_position_opts(opts, slide.slide_width, slide.slide_height)
    table = Table.new(slide.next_shape_id, rows, opts)
    %{slide | tables: slide.tables ++ [table], next_shape_id: slide.next_shape_id + 1}
  end

  @doc """
  Generates the slide XML including all shapes, chart graphic frames, and images.
  `chart_rids` is a list of {chart, rId} tuples.
  `image_rids` is a list of {image, rId} tuples.
  """
  @spec to_xml(
          t(),
          [{Podium.Chart.t(), String.t()}],
          [{Podium.Image.t(), String.t()}],
          %{pos_integer() => String.t()},
          %{String.t() => String.t()},
          String.t() | nil,
          [{Podium.Video.t(), String.t(), String.t(), String.t()}]
        ) :: String.t()
  def to_xml(
        %__MODULE__{} = slide,
        chart_rids \\ [],
        image_rids \\ [],
        fill_rids \\ %{},
        hyperlink_rids \\ %{},
        bg_rid \\ nil,
        video_rids \\ []
      ) do
    shapes_xml =
      Enum.map(slide.shapes, fn shape ->
        Shape.to_xml(shape, Map.get(fill_rids, shape.id), hyperlink_rids)
      end)
      |> Enum.join()

    charts_xml =
      chart_rids
      |> Enum.with_index()
      |> Enum.map(fn {{chart, rid}, idx} ->
        shape_id = slide.next_shape_id + idx
        Podium.Chart.graphic_frame_xml(chart, shape_id, rid)
      end)
      |> Enum.join()

    images_xml =
      image_rids
      |> Enum.with_index()
      |> Enum.map(fn {{image, rid}, idx} ->
        shape_id = slide.next_shape_id + length(chart_rids) + idx
        Image.pic_xml(image, shape_id, rid)
      end)
      |> Enum.join()

    tables_xml =
      slide.tables
      |> Enum.with_index()
      |> Enum.map(fn {table, idx} ->
        shape_id = slide.next_shape_id + length(chart_rids) + length(image_rids) + idx
        Table.to_xml(%{table | id: shape_id})
      end)
      |> Enum.join()

    connectors_xml =
      slide.connectors
      |> Enum.map(&Connector.to_xml/1)
      |> Enum.join()

    # Video shape IDs start after tables+connectors+images+charts
    video_base_id =
      slide.next_shape_id + length(chart_rids) + length(image_rids) +
        length(slide.tables) + length(slide.connectors)

    videos_xml =
      video_rids
      |> Enum.with_index()
      |> Enum.map(fn {{video, video_rid, media_rid, poster_rid}, idx} ->
        shape_id = video_base_id + idx
        Video.pic_xml(video, shape_id, video_rid, media_rid, poster_rid)
      end)
      |> Enum.join()

    timing_xml = build_timing_xml(video_rids, video_base_id)

    placeholders_xml =
      slide.placeholders
      |> Enum.map(&Podium.Placeholder.to_xml(&1, hyperlink_rids))
      |> Enum.join()

    Podium.XML.Builder.xml_declaration() <>
      ~s(<p:sld xmlns:a="#{Constants.ns(:a)}" xmlns:p="#{Constants.ns(:p)}" xmlns:r="#{Constants.ns(:r)}">) <>
      ~s(<p:cSld>) <>
      background_xml(slide.background, bg_rid) <>
      ~s(<p:spTree>) <>
      ~s(<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>) <>
      ~s(<p:grpSpPr/>) <>
      placeholders_xml <>
      shapes_xml <>
      charts_xml <>
      images_xml <>
      tables_xml <>
      connectors_xml <>
      videos_xml <>
      ~s(</p:spTree></p:cSld>) <>
      ~s(<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>) <>
      timing_xml <>
      ~s(</p:sld>)
  end

  defp build_timing_xml([], _base_id), do: ""

  defp build_timing_xml(video_rids, base_id) do
    children =
      video_rids
      |> Enum.with_index()
      |> Enum.map(fn {_video_rid_tuple, idx} ->
        shape_id = base_id + idx
        ctn_id = 2 + idx
        Video.video_timing_xml(shape_id, ctn_id)
      end)
      |> Enum.join()

    ~s(<p:timing><p:tnLst><p:par>) <>
      ~s(<p:cTn id="1" dur="indefinite" restart="never" nodeType="tmRoot">) <>
      ~s(<p:childTnLst>) <>
      children <>
      ~s(</p:childTnLst>) <>
      ~s(</p:cTn>) <>
      ~s(</p:par></p:tnLst></p:timing>)
  end

  defp background_xml(nil, _bg_rid), do: ""

  defp background_xml({:picture, _binary}, bg_rid) when is_binary(bg_rid) do
    fill = Drawing.fill_xml({:picture, bg_rid, [mode: :stretch]})
    ~s(<p:bg><p:bgPr>#{fill}<a:effectLst/></p:bgPr></p:bg>)
  end

  defp background_xml(fill, _bg_rid) do
    ~s(<p:bg><p:bgPr>#{Drawing.fill_xml(fill)}<a:effectLst/></p:bgPr></p:bg>)
  end

  defp detect_fill_extension(<<0x89, 0x50, 0x4E, 0x47, _::binary>>), do: "png"
  defp detect_fill_extension(<<0xFF, 0xD8, _::binary>>), do: "jpeg"
  defp detect_fill_extension(<<0x42, 0x4D, _::binary>>), do: "bmp"
  defp detect_fill_extension(<<0x47, 0x49, 0x46, _::binary>>), do: "gif"
  defp detect_fill_extension(_), do: "png"

  defp resolve_layout_index(:title_slide), do: 1
  defp resolve_layout_index(:title_content), do: 2
  defp resolve_layout_index(:section_header), do: 3
  defp resolve_layout_index(:two_content), do: 4
  defp resolve_layout_index(:comparison), do: 5
  defp resolve_layout_index(:title_only), do: 6
  defp resolve_layout_index(:blank), do: @blank_layout_index
  defp resolve_layout_index(:content_caption), do: 8
  defp resolve_layout_index(:picture_caption), do: 9
  defp resolve_layout_index(:title_vertical_text), do: 10
  defp resolve_layout_index(:vertical_title_text), do: 11
  defp resolve_layout_index(index) when is_integer(index), do: index

  @doc false
  def layout_atom(1), do: :title_slide
  def layout_atom(2), do: :title_content
  def layout_atom(3), do: :section_header
  def layout_atom(4), do: :two_content
  def layout_atom(5), do: :comparison
  def layout_atom(6), do: :title_only
  def layout_atom(7), do: :blank
  def layout_atom(8), do: :content_caption
  def layout_atom(9), do: :picture_caption
  def layout_atom(10), do: :title_vertical_text
  def layout_atom(11), do: :vertical_title_text

  def layout_atom(n) when is_integer(n) do
    raise ArgumentError, "unknown layout index #{n}; expected 1..11"
  end

  defp resolve_position_opts(opts, slide_width, slide_height) do
    opts
    |> resolve_dim(:x, slide_width)
    |> resolve_dim(:y, slide_height)
    |> resolve_dim(:width, slide_width)
    |> resolve_dim(:height, slide_height)
  end

  defp resolve_dim(opts, key, reference) do
    case Keyword.get(opts, key) do
      {_, :percent} = pct -> Keyword.put(opts, key, Units.resolve_percent(pct, reference))
      _ -> opts
    end
  end

  defp maybe_resolve_percent({_, :percent} = pct, ref), do: Units.resolve_percent(pct, ref)
  defp maybe_resolve_percent(other, _ref), do: other
end
