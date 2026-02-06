defmodule Podium.Chart.XmlWriter do
  @moduledoc false

  alias Podium.Chart.{ChartData, ChartType}
  alias Podium.OPC.Constants
  alias Podium.XML.Builder

  @cat_ax_id "-2068027336"
  @val_ax_id "-2113994440"

  @line_cat_ax_id "2118791784"
  @line_val_ax_id "2140495176"

  @doc """
  Generates the chart XML for the given chart type and data.
  """
  def to_xml(chart_type, %ChartData{} = chart_data) do
    config = ChartType.config(chart_type)

    Builder.xml_declaration() <>
      chart_space_xml(chart_type, config, chart_data)
  end

  defp chart_space_xml(chart_type, config, chart_data) do
    ns_c = Constants.ns(:c)
    ns_a = Constants.ns(:a)
    ns_r = Constants.ns(:r)

    ~s(<c:chartSpace xmlns:c="#{ns_c}" xmlns:a="#{ns_a}" xmlns:r="#{ns_r}">) <>
      date1904_xml(config) <>
      ~s(<c:chart>) <>
      ~s(<c:autoTitleDeleted val="0"/>) <>
      ~s(<c:plotArea>) <>
      plot_xml(chart_type, config, chart_data) <>
      axes_xml(chart_type, config) <>
      ~s(</c:plotArea>) <>
      ~s(<c:dispBlanksAs val="gap"/>) <>
      ~s(</c:chart>) <>
      txpr_xml() <>
      ~s(<c:externalData r:id="rId1"><c:autoUpdate val="0"/></c:externalData>) <>
      ~s(</c:chartSpace>)
  end

  defp date1904_xml(%{element: "c:pieChart"}), do: ""
  defp date1904_xml(_), do: ~s(<c:date1904 val="0"/>)

  defp plot_xml(chart_type, %{element: "c:barChart"} = config, chart_data) do
    ~s(<c:barChart>) <>
      ~s(<c:barDir val="#{config.bar_dir}"/>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      series_xml(chart_type, chart_data) <>
      overlap_xml(config) <>
      ~s(<c:axId val="#{@cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@val_ax_id}"/>) <>
      ~s(</c:barChart>)
  end

  defp plot_xml(chart_type, %{element: "c:lineChart"} = config, chart_data) do
    ~s(<c:lineChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml(chart_type, chart_data) <>
      ~s(<c:marker val="1"/>) <>
      ~s(<c:smooth val="0"/>) <>
      ~s(<c:axId val="#{@line_cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@line_val_ax_id}"/>) <>
      ~s(</c:lineChart>)
  end

  defp plot_xml(chart_type, %{element: "c:pieChart"}, chart_data) do
    ~s(<c:pieChart>) <>
      ~s(<c:varyColors val="1"/>) <>
      series_xml(chart_type, chart_data) <>
      ~s(</c:pieChart>)
  end

  defp overlap_xml(%{overlap: nil}), do: ""
  defp overlap_xml(%{overlap: val}), do: ~s(<c:overlap val="#{val}"/>)

  defp series_xml(chart_type, chart_data) do
    chart_data.series
    |> Enum.map(fn series -> single_series_xml(chart_type, chart_data, series) end)
    |> Enum.join()
  end

  defp single_series_xml(chart_type, chart_data, series) do
    config = ChartType.config(chart_type)

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

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      marker_xml <>
      cat_xml(chart_data) <>
      val_xml(chart_data, series) <>
      smooth_xml <>
      ~s(</c:ser>)
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

  defp axes_xml(_chart_type, %{has_axes: false}), do: ""

  defp axes_xml(chart_type, %{element: "c:lineChart"}) do
    cat_ax_xml(chart_type, @line_cat_ax_id, @line_val_ax_id) <>
      val_ax_xml(chart_type, @line_val_ax_id, @line_cat_ax_id)
  end

  defp axes_xml(chart_type, _config) do
    cat_ax_xml(chart_type, @cat_ax_id, @val_ax_id) <>
      val_ax_xml(chart_type, @val_ax_id, @cat_ax_id)
  end

  defp cat_ax_xml(chart_type, ax_id, cross_ax_id) do
    pos = ChartType.cat_ax_pos(chart_type)

    ~s(<c:catAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      ~s(<c:scaling><c:orientation val="minMax"/></c:scaling>) <>
      ~s(<c:delete val="0"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
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

  defp val_ax_xml(chart_type, ax_id, cross_ax_id) do
    pos = ChartType.val_ax_pos(chart_type)

    ~s(<c:valAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      ~s(<c:scaling/>) <>
      ~s(<c:delete val="0"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      ~s(<c:majorGridlines/>) <>
      ~s(<c:majorTickMark val="out"/>) <>
      ~s(<c:minorTickMark val="none"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      ~s(<c:crosses val="autoZero"/>) <>
      ~s(</c:valAx>)
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
