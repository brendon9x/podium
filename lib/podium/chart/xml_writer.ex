defmodule Podium.Chart.XmlWriter do
  @moduledoc false

  alias Podium.Chart
  alias Podium.Chart.{ChartData, ChartType}
  alias Podium.OPC.Constants
  alias Podium.XML.Builder

  @cat_ax_id "-2068027336"
  @val_ax_id "-2113994440"

  @line_cat_ax_id "2118791784"
  @line_val_ax_id "2140495176"

  @doc """
  Generates the chart XML. Accepts either a `%Chart{}` struct or
  `(chart_type, chart_data)` for backwards compatibility.
  """
  def to_xml(%Chart{} = chart) do
    config = ChartType.config(chart.chart_type)

    Builder.xml_declaration() <>
      chart_space_xml(chart, config)
  end

  def to_xml(chart_type, %ChartData{} = chart_data) do
    chart = %Chart{chart_type: chart_type, chart_data: chart_data}
    to_xml(chart)
  end

  defp chart_space_xml(chart, config) do
    ns_c = Constants.ns(:c)
    ns_a = Constants.ns(:a)
    ns_r = Constants.ns(:r)

    ~s(<c:chartSpace xmlns:c="#{ns_c}" xmlns:a="#{ns_a}" xmlns:r="#{ns_r}">) <>
      date1904_xml(config) <>
      ~s(<c:chart>) <>
      title_xml(chart.title) <>
      ~s(<c:plotArea>) <>
      plot_xml(chart, config) <>
      axes_xml(chart, config) <>
      ~s(</c:plotArea>) <>
      legend_xml(chart.legend) <>
      ~s(<c:dispBlanksAs val="gap"/>) <>
      ~s(</c:chart>) <>
      txpr_xml() <>
      ~s(<c:externalData r:id="rId1"><c:autoUpdate val="0"/></c:externalData>) <>
      ~s(</c:chartSpace>)
  end

  # -- Title --

  defp title_xml(nil), do: ~s(<c:autoTitleDeleted val="1"/>)

  defp title_xml(title) when is_binary(title) do
    escaped = Builder.escape(title)

    ~s(<c:title>) <>
      ~s(<c:tx><c:rich>) <>
      ~s(<a:bodyPr/><a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escaped}</a:t></a:r></a:p>) <>
      ~s(</c:rich></c:tx>) <>
      ~s(<c:overlay val="0"/>) <>
      ~s(</c:title>)
  end

  # -- Legend --

  defp legend_xml(nil), do: ""
  defp legend_xml(false), do: ""

  defp legend_xml(position) when position in [:left, :right, :top, :bottom] do
    pos =
      case position do
        :left -> "l"
        :right -> "r"
        :top -> "t"
        :bottom -> "b"
      end

    ~s(<c:legend><c:legendPos val="#{pos}"/><c:overlay val="0"/></c:legend>)
  end

  # -- Date1904 --

  defp date1904_xml(%{element: "c:pieChart"}), do: ""
  defp date1904_xml(_), do: ~s(<c:date1904 val="0"/>)

  # -- Plot --

  defp plot_xml(chart, %{element: "c:barChart"} = config) do
    ~s(<c:barChart>) <>
      ~s(<c:barDir val="#{config.bar_dir}"/>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      overlap_xml(config) <>
      ~s(<c:axId val="#{@cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@val_ax_id}"/>) <>
      ~s(</c:barChart>)
  end

  defp plot_xml(chart, %{element: "c:lineChart"} = config) do
    ~s(<c:lineChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:marker val="1"/>) <>
      ~s(<c:smooth val="0"/>) <>
      ~s(<c:axId val="#{@line_cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@line_val_ax_id}"/>) <>
      ~s(</c:lineChart>)
  end

  defp plot_xml(chart, %{element: "c:pieChart"}) do
    ~s(<c:pieChart>) <>
      ~s(<c:varyColors val="1"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(</c:pieChart>)
  end

  # -- Data Labels --

  defp data_labels_xml([]), do: ""

  defp data_labels_xml(labels) when is_list(labels) do
    show_val = if :value in labels, do: ~s(<c:showVal val="1"/>), else: ~s(<c:showVal val="0"/>)

    show_cat =
      if :category in labels,
        do: ~s(<c:showCatName val="1"/>),
        else: ~s(<c:showCatName val="0"/>)

    show_ser =
      if :series in labels,
        do: ~s(<c:showSerName val="1"/>),
        else: ~s(<c:showSerName val="0"/>)

    show_pct =
      if :percent in labels, do: ~s(<c:showPercent val="1"/>), else: ~s(<c:showPercent val="0"/>)

    ~s(<c:dLbls>) <>
      show_val <>
      show_cat <>
      show_ser <>
      show_pct <>
      ~s(<c:showLegendKey val="0"/>) <>
      ~s(</c:dLbls>)
  end

  defp overlap_xml(%{overlap: nil}), do: ""
  defp overlap_xml(%{overlap: val}), do: ~s(<c:overlap val="#{val}"/>)

  # -- Series --

  defp series_xml(chart) do
    config = ChartType.config(chart.chart_type)

    chart.chart_data.series
    |> Enum.map(fn series -> single_series_xml(config, chart.chart_data, series) end)
    |> Enum.join()
  end

  defp single_series_xml(config, chart_data, series) do
    marker_xml =
      case config do
        %{element: "c:lineChart", show_marker: false} ->
          ~s(<c:marker><c:symbol val="none"/></c:marker>)

        _ ->
          ""
      end

    smooth_xml =
      case config.element do
        "c:lineChart" -> ~s(<c:smooth val="0"/>)
        _ -> ""
      end

    color_xml = series_color_xml(config, series)

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      marker_xml <>
      cat_xml(chart_data) <>
      val_xml(chart_data, series) <>
      smooth_xml <>
      ~s(</c:ser>)
  end

  defp series_color_xml(_config, %{color: nil}), do: ""

  defp series_color_xml(%{element: "c:lineChart"}, %{color: color}) do
    ~s(<c:spPr><a:ln><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></a:ln></c:spPr>)
  end

  defp series_color_xml(_config, %{color: color}) do
    ~s(<c:spPr><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></c:spPr>)
  end

  defp tx_xml(chart_data, series) do
    name_ref = ChartData.series_name_ref(chart_data, series)
    escaped_name = Builder.escape(series.name)

    ~s(<c:tx>) <>
      ~s(<c:strRef>) <>
      ~s(<c:f>#{name_ref}</c:f>) <>
      ~s(<c:strCache>) <>
      ~s(<c:ptCount val="1"/>) <>
      ~s(<c:pt idx="0"><c:v>#{escaped_name}</c:v></c:pt>) <>
      ~s(</c:strCache>) <>
      ~s(</c:strRef>) <>
      ~s(</c:tx>)
  end

  defp cat_xml(chart_data) do
    cats_ref = ChartData.categories_ref(chart_data)
    cat_count = length(chart_data.categories)

    pts =
      chart_data.categories
      |> Enum.with_index()
      |> Enum.map(fn {cat, idx} ->
        ~s(<c:pt idx="#{idx}"><c:v>#{Builder.escape(to_string(cat))}</c:v></c:pt>)
      end)
      |> Enum.join()

    ~s(<c:cat>) <>
      ~s(<c:strRef>) <>
      ~s(<c:f>#{cats_ref}</c:f>) <>
      ~s(<c:strCache>) <>
      ~s(<c:ptCount val="#{cat_count}"/>) <>
      pts <>
      ~s(</c:strCache>) <>
      ~s(</c:strRef>) <>
      ~s(</c:cat>)
  end

  defp val_xml(chart_data, series) do
    vals_ref = ChartData.series_values_ref(chart_data, series)
    val_count = length(series.values)

    pts =
      series.values
      |> Enum.with_index()
      |> Enum.map(fn {val, idx} ->
        ~s(<c:pt idx="#{idx}"><c:v>#{val}</c:v></c:pt>)
      end)
      |> Enum.join()

    ~s(<c:val>) <>
      ~s(<c:numRef>) <>
      ~s(<c:f>#{vals_ref}</c:f>) <>
      ~s(<c:numCache>) <>
      ~s(<c:formatCode>General</c:formatCode>) <>
      ~s(<c:ptCount val="#{val_count}"/>) <>
      pts <>
      ~s(</c:numCache>) <>
      ~s(</c:numRef>) <>
      ~s(</c:val>)
  end

  # -- Axes --

  defp axes_xml(_chart, %{has_axes: false}), do: ""

  defp axes_xml(chart, %{element: "c:lineChart"}) do
    cat_ax_xml(chart, @line_cat_ax_id, @line_val_ax_id) <>
      val_ax_xml(chart, @line_val_ax_id, @line_cat_ax_id)
  end

  defp axes_xml(chart, _config) do
    cat_ax_xml(chart, @cat_ax_id, @val_ax_id) <>
      val_ax_xml(chart, @val_ax_id, @cat_ax_id)
  end

  defp cat_ax_xml(chart, ax_id, cross_ax_id) do
    pos = ChartType.cat_ax_pos(chart.chart_type)
    axis_opts = chart.category_axis || []
    axis_title = Keyword.get(axis_opts, :title)

    ~s(<c:catAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      ~s(<c:scaling><c:orientation val="minMax"/></c:scaling>) <>
      ~s(<c:delete val="0"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      axis_title_xml(axis_title) <>
      ~s(<c:majorTickMark val="out"/>) <>
      ~s(<c:minorTickMark val="none"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      ~s(<c:crosses val="autoZero"/>) <>
      ~s(<c:auto val="1"/>) <>
      ~s(<c:lblAlgn val="ctr"/>) <>
      ~s(<c:lblOffset val="100"/>) <>
      ~s(<c:noMultiLvlLbl val="0"/>) <>
      ~s(</c:catAx>)
  end

  defp val_ax_xml(chart, ax_id, cross_ax_id) do
    pos = ChartType.val_ax_pos(chart.chart_type)
    axis_opts = chart.value_axis || []
    axis_title = Keyword.get(axis_opts, :title)
    num_fmt = Keyword.get(axis_opts, :number_format)
    gridlines = Keyword.get(axis_opts, :major_gridlines, true)
    min_val = Keyword.get(axis_opts, :min)
    max_val = Keyword.get(axis_opts, :max)
    major_unit = Keyword.get(axis_opts, :major_unit)

    scaling_xml = val_scaling_xml(min_val, max_val)
    gridlines_xml = if gridlines, do: ~s(<c:majorGridlines/>), else: ""
    num_fmt_xml = val_num_fmt_xml(num_fmt)
    major_unit_xml = if major_unit, do: ~s(<c:majorUnit val="#{major_unit}"/>), else: ""

    ~s(<c:valAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      scaling_xml <>
      ~s(<c:delete val="0"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      gridlines_xml <>
      axis_title_xml(axis_title) <>
      num_fmt_xml <>
      ~s(<c:majorTickMark val="out"/>) <>
      ~s(<c:minorTickMark val="none"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      ~s(<c:crosses val="autoZero"/>) <>
      major_unit_xml <>
      ~s(</c:valAx>)
  end

  defp val_scaling_xml(nil, nil), do: ~s(<c:scaling/>)

  defp val_scaling_xml(min_val, max_val) do
    min_xml = if min_val, do: ~s(<c:min val="#{min_val}"/>), else: ""
    max_xml = if max_val, do: ~s(<c:max val="#{max_val}"/>), else: ""
    ~s(<c:scaling>#{min_xml}#{max_xml}</c:scaling>)
  end

  defp val_num_fmt_xml(nil), do: ""

  defp val_num_fmt_xml(fmt) do
    ~s(<c:numFmt formatCode="#{Builder.escape(fmt)}" sourceLinked="0"/>)
  end

  defp axis_title_xml(nil), do: ""

  defp axis_title_xml(title) do
    escaped = Builder.escape(title)

    ~s(<c:title>) <>
      ~s(<c:tx><c:rich>) <>
      ~s(<a:bodyPr/><a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escaped}</a:t></a:r></a:p>) <>
      ~s(</c:rich></c:tx>) <>
      ~s(<c:overlay val="0"/>) <>
      ~s(</c:title>)
  end

  defp txpr_xml do
    ~s(<c:txPr>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p>) <>
      ~s(<a:pPr><a:defRPr sz="1800"/></a:pPr>) <>
      ~s(<a:endParaRPr lang="en-US"/>) <>
      ~s(</a:p>) <>
      ~s(</c:txPr>)
  end
end
