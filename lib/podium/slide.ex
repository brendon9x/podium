defmodule Podium.Slide do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.{Drawing, Image, Shape, Table}

  @blank_layout_index 7

  defstruct [
    :index,
    :layout_index,
    :pres_rid,
    background: nil,
    background_image: nil,
    notes_text: nil,
    shapes: [],
    charts: [],
    images: [],
    tables: [],
    placeholders: [],
    picture_placeholders: [],
    fill_images: [],
    next_shape_id: 2
  ]

  @doc """
  Creates a new blank slide.
  """
  def new(opts \\ []) do
    %__MODULE__{
      index: Keyword.get(opts, :index, 1),
      layout_index: Keyword.get(opts, :layout_index, @blank_layout_index)
    }
  end

  @doc """
  Returns the partname for this slide within the package.
  """
  def partname(%__MODULE__{index: index}), do: "ppt/slides/slide#{index}.xml"

  @doc """
  Returns the rels partname for this slide.
  """
  def rels_partname(%__MODULE__{index: index}),
    do: "ppt/slides/_rels/slide#{index}.xml.rels"

  @doc """
  Adds a text box shape to the slide.
  """
  def add_text_box(%__MODULE__{} = slide, text, opts) do
    shape = Shape.text_box(slide.next_shape_id, text, opts)

    %{slide | shapes: slide.shapes ++ [shape], next_shape_id: slide.next_shape_id + 1}
  end

  @doc """
  Adds a text box with a picture fill. The image binary is stored for packaging.
  """
  def add_picture_fill_text_box(%__MODULE__{} = slide, text, image_binary, opts) do
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

  defp detect_fill_extension(<<0x89, 0x50, 0x4E, 0x47, _::binary>>), do: "png"
  defp detect_fill_extension(<<0xFF, 0xD8, _::binary>>), do: "jpeg"
  defp detect_fill_extension(<<0x42, 0x4D, _::binary>>), do: "bmp"
  defp detect_fill_extension(<<0x47, 0x49, 0x46, _::binary>>), do: "gif"
  defp detect_fill_extension(_), do: "png"

  @doc """
  Adds a chart to the slide. Returns the updated slide.
  """
  def add_chart(%__MODULE__{} = slide, chart_type, chart_data, chart_index, opts) do
    chart = Podium.Chart.new(chart_type, chart_data, chart_index, opts)

    %{
      slide
      | charts: slide.charts ++ [chart],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Adds an image to the slide. Returns the updated slide.
  """
  def add_image(%__MODULE__{} = slide, image) do
    %{
      slide
      | images: slide.images ++ [image],
        next_shape_id: slide.next_shape_id + 1
    }
  end

  @doc """
  Adds a table to the slide.
  """
  def add_table(%__MODULE__{} = slide, rows, opts) do
    table = Table.new(slide.next_shape_id, rows, opts)
    %{slide | tables: slide.tables ++ [table], next_shape_id: slide.next_shape_id + 1}
  end

  @doc """
  Generates the slide XML including all shapes, chart graphic frames, and images.
  `chart_rids` is a list of {chart, rId} tuples.
  `image_rids` is a list of {image, rId} tuples.
  """
  def to_xml(
        %__MODULE__{} = slide,
        chart_rids \\ [],
        image_rids \\ [],
        fill_rids \\ %{},
        hyperlink_rids \\ %{},
        bg_rid \\ nil
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
      ~s(</p:spTree></p:cSld>) <>
      ~s(<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>) <>
      ~s(</p:sld>)
  end

  defp background_xml(nil, _bg_rid), do: ""

  defp background_xml({:picture, _binary}, bg_rid) when is_binary(bg_rid) do
    fill = Drawing.fill_xml({:picture, bg_rid, [mode: :stretch]})
    ~s(<p:bg><p:bgPr>#{fill}<a:effectLst/></p:bgPr></p:bg>)
  end

  defp background_xml(fill, _bg_rid) do
    ~s(<p:bg><p:bgPr>#{Drawing.fill_xml(fill)}<a:effectLst/></p:bgPr></p:bg>)
  end
end
