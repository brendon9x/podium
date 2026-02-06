defmodule Podium.Slide do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.Shape

  defstruct [
    :index,
    :layout_index,
    shapes: [],
    charts: [],
    next_shape_id: 2
  ]

  @doc """
  Creates a new blank slide.
  """
  def new(opts \\ []) do
    %__MODULE__{
      index: Keyword.get(opts, :index, 1),
      layout_index: Keyword.get(opts, :layout_index, 7)
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
  Generates the slide XML including all shapes and chart graphic frames.
  Chart graphic frames need the relationship IDs that link the slide to each chart.
  `chart_rids` is a list of {chart, rId} tuples.
  """
  def to_xml(%__MODULE__{} = slide, chart_rids \\ []) do
    shapes_xml = Enum.map(slide.shapes, & &1.to_xml.(&1)) |> Enum.join()

    # Build graphic frames for charts
    # Shape IDs for charts start after text box shapes
    base_chart_shape_id =
      if slide.shapes == [], do: 2, else: Enum.max_by(slide.shapes, & &1.id).id + 1

    charts_xml =
      chart_rids
      |> Enum.with_index()
      |> Enum.map(fn {{chart, rid}, idx} ->
        shape_id = base_chart_shape_id + idx
        Podium.Chart.graphic_frame_xml(chart, shape_id, rid)
      end)
      |> Enum.join()

    Podium.XML.Builder.xml_declaration() <>
      ~s(<p:sld xmlns:a="#{Constants.ns(:a)}" xmlns:p="#{Constants.ns(:p)}" xmlns:r="#{Constants.ns(:r)}">) <>
      ~s(<p:cSld><p:spTree>) <>
      ~s(<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>) <>
      ~s(<p:grpSpPr/>) <>
      shapes_xml <>
      charts_xml <>
      ~s(</p:spTree></p:cSld>) <>
      ~s(<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>) <>
      ~s(</p:sld>)
  end
end
