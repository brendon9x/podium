defmodule Podium.Chart do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.Units

  defstruct [
    :chart_type,
    :chart_data,
    :chart_index,
    :x,
    :y,
    :width,
    :height,
    :title,
    :legend,
    data_labels: [],
    category_axis: [],
    value_axis: []
  ]

  @doc """
  Creates a new chart.
  """
  def new(chart_type, chart_data, chart_index, opts) do
    %__MODULE__{
      chart_type: chart_type,
      chart_data: chart_data,
      chart_index: chart_index,
      x: Units.to_emu(Keyword.fetch!(opts, :x)),
      y: Units.to_emu(Keyword.fetch!(opts, :y)),
      width: Units.to_emu(Keyword.fetch!(opts, :width)),
      height: Units.to_emu(Keyword.fetch!(opts, :height)),
      title: Keyword.get(opts, :title),
      legend: Keyword.get(opts, :legend),
      data_labels: Keyword.get(opts, :data_labels, []),
      category_axis: Keyword.get(opts, :category_axis, []),
      value_axis: Keyword.get(opts, :value_axis, [])
    }
  end

  @doc """
  Returns the partname for the chart XML.
  """
  def partname(%__MODULE__{chart_index: idx}), do: "ppt/charts/chart#{idx}.xml"

  @doc """
  Returns the rels partname for this chart.
  """
  def rels_partname(%__MODULE__{chart_index: idx}),
    do: "ppt/charts/_rels/chart#{idx}.xml.rels"

  @doc """
  Returns the partname for the embedded Excel workbook.
  """
  def xlsx_partname(%__MODULE__{chart_index: idx}),
    do: "ppt/embeddings/Microsoft_Excel_Sheet#{idx}.xlsx"

  @doc """
  Generates the graphic frame XML for embedding the chart in a slide.
  The `shape_id` is the shape ID within the slide, and `r_id` is the
  relationship ID linking to the chart part.
  """
  def graphic_frame_xml(%__MODULE__{} = chart, shape_id, r_id) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)
    ns_c = Constants.ns(:c)

    ~s(<p:graphicFrame xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvGraphicFramePr>) <>
      ~s(<p:cNvPr id="#{shape_id}" name="Chart #{chart.chart_index}"/>) <>
      ~s(<p:cNvGraphicFramePr><a:graphicFrameLocks noGrp="1"/></p:cNvGraphicFramePr>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvGraphicFramePr>) <>
      ~s(<p:xfrm>) <>
      ~s(<a:off x="#{chart.x}" y="#{chart.y}"/>) <>
      ~s(<a:ext cx="#{chart.width}" cy="#{chart.height}"/>) <>
      ~s(</p:xfrm>) <>
      ~s(<a:graphic>) <>
      ~s(<a:graphicData uri="#{ns_c}">) <>
      ~s(<c:chart xmlns:c="#{ns_c}" r:id="#{r_id}"/>) <>
      ~s(</a:graphicData>) <>
      ~s(</a:graphic>) <>
      ~s(</p:graphicFrame>)
  end
end
