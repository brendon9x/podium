defmodule Podium.Slide do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.{Image, Shape, Table}

  @blank_layout_index 7

  defstruct [
    :index,
    :layout_index,
    :pres_rid,
    shapes: [],
    charts: [],
    images: [],
    tables: [],
    placeholders: [],
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
  def to_xml(%__MODULE__{} = slide, chart_rids \\ [], image_rids \\ []) do
    shapes_xml = Enum.map(slide.shapes, &Shape.to_xml/1) |> Enum.join()

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
      |> Enum.map(&Podium.Placeholder.to_xml/1)
      |> Enum.join()

    Podium.XML.Builder.xml_declaration() <>
      ~s(<p:sld xmlns:a="#{Constants.ns(:a)}" xmlns:p="#{Constants.ns(:p)}" xmlns:r="#{Constants.ns(:r)}">) <>
      ~s(<p:cSld><p:spTree>) <>
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
end
