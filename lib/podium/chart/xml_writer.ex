defmodule Podium.Chart.XmlWriter do
  @moduledoc """
  Chart XML generation for the chart part (`ppt/charts/chartN.xml`).

  Renders the complete chart XML including plot area, series, axes, title,
  legend, and data labels for all supported chart types.
  """

  alias Podium.Chart
  alias Podium.Chart.{BubbleChartData, ChartData, ChartType, ComboChart, XyChartData}
  alias Podium.{Drawing, Pattern}
  alias Podium.OPC.Constants
  alias Podium.XML.Builder

  @cat_ax_id "-2068027336"
  @val_ax_id "-2113994440"

  @line_cat_ax_id "2118791784"
  @line_val_ax_id "2140495176"

  @area_cat_ax_id "2094734552"
  @area_val_ax_id "2094734553"

  @radar_cat_ax_id "2094734554"
  @radar_val_ax_id "2094734555"

  @scatter_x_ax_id "2094734556"
  @scatter_y_ax_id "2094734557"

  @combo_cat_ax_id "10000"
  @combo_val_ax_id "10001"
  @combo_secondary_val_ax_id "10002"

  @doc """
  Generates the chart XML. Accepts either a `%Chart{}` struct or
  `(chart_type, chart_data)` for backwards compatibility.
  """
  @spec to_xml(Podium.Chart.t()) :: String.t()
  @spec to_xml(atom(), struct()) :: String.t()
  def to_xml(%Chart{combo: %ComboChart{}} = chart) do
    Builder.xml_declaration() <> combo_chart_space_xml(chart)
  end

  def to_xml(%Chart{} = chart) do
    config = ChartType.config(chart.chart_type)

    Builder.xml_declaration() <>
      chart_space_xml(chart, config)
  end

  def to_xml(chart_type, chart_data) do
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
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escaped}</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>) <>
      ~s(</c:rich></c:tx>) <>
      ~s(<c:overlay val="0"/>) <>
      ~s(</c:title>)
  end

  defp title_xml(opts) when is_list(opts) do
    text = Keyword.fetch!(opts, :text)
    escaped = Builder.escape(text)
    rpr_xml = font_rpr_xml(opts)

    ~s(<c:title>) <>
      ~s(<c:tx><c:rich>) <>
      ~s(<a:bodyPr/><a:lstStyle/>) <>
      ~s(<a:p><a:r>#{rpr_xml}<a:t>#{escaped}</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>) <>
      ~s(</c:rich></c:tx>) <>
      ~s(<c:overlay val="0"/>) <>
      ~s(</c:title>)
  end

  # -- Legend --

  defp legend_xml(nil), do: ""
  defp legend_xml(false), do: ""

  defp legend_xml(position) when position in [:left, :right, :top, :bottom] do
    pos = legend_pos_value(position)
    ~s(<c:legend><c:legendPos val="#{pos}"/><c:overlay val="0"/></c:legend>)
  end

  defp legend_xml(opts) when is_list(opts) do
    position = Keyword.fetch!(opts, :position)
    pos = legend_pos_value(position)
    font_xml = legend_font_xml(opts)

    ~s(<c:legend><c:legendPos val="#{pos}"/><c:overlay val="0"/>#{font_xml}</c:legend>)
  end

  defp legend_pos_value(:left), do: "l"
  defp legend_pos_value(:right), do: "r"
  defp legend_pos_value(:top), do: "t"
  defp legend_pos_value(:bottom), do: "b"

  defp legend_font_xml(opts) do
    font_size = Keyword.get(opts, :font_size)
    bold = Keyword.get(opts, :bold)
    italic = Keyword.get(opts, :italic)
    color = Keyword.get(opts, :color)
    font = Keyword.get(opts, :font)

    if font_size || bold || italic || color || font do
      attrs = font_rpr_attrs(opts)
      children = font_rpr_children(opts)

      if children == "" do
        ~s(<c:txPr><a:bodyPr/><a:lstStyle/><a:p><a:pPr><a:defRPr #{attrs}/></a:pPr><a:endParaRPr lang="en-US"/></a:p></c:txPr>)
      else
        ~s(<c:txPr><a:bodyPr/><a:lstStyle/><a:p><a:pPr><a:defRPr #{attrs}>#{children}</a:defRPr></a:pPr><a:endParaRPr lang="en-US"/></a:p></c:txPr>)
      end
    else
      ""
    end
  end

  # -- Date1904 --

  defp date1904_xml(%{element: "c:pieChart"}), do: ""
  defp date1904_xml(%{element: "c:doughnutChart"}), do: ""
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

  defp plot_xml(chart, %{element: "c:areaChart"} = config) do
    ~s(<c:areaChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:axId val="#{@area_cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@area_val_ax_id}"/>) <>
      ~s(</c:areaChart>)
  end

  defp plot_xml(chart, %{element: "c:doughnutChart"}) do
    ~s(<c:doughnutChart>) <>
      ~s(<c:varyColors val="1"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:firstSliceAng val="0"/>) <>
      ~s(<c:holeSize val="50"/>) <>
      ~s(</c:doughnutChart>)
  end

  defp plot_xml(chart, %{element: "c:radarChart"} = config) do
    ~s(<c:radarChart>) <>
      ~s(<c:radarStyle val="#{config.radar_style}"/>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:axId val="#{@radar_cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@radar_val_ax_id}"/>) <>
      ~s(</c:radarChart>)
  end

  defp plot_xml(chart, %{element: "c:scatterChart"} = config) do
    ~s(<c:scatterChart>) <>
      ~s(<c:scatterStyle val="#{config.scatter_style}"/>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:axId val="#{@scatter_x_ax_id}"/>) <>
      ~s(<c:axId val="#{@scatter_y_ax_id}"/>) <>
      ~s(</c:scatterChart>)
  end

  defp plot_xml(chart, %{element: "c:bubbleChart"}) do
    ~s(<c:bubbleChart>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:bubbleScale val="100"/>) <>
      ~s(<c:showNegBubbles val="0"/>) <>
      ~s(<c:axId val="#{@scatter_x_ax_id}"/>) <>
      ~s(<c:axId val="#{@scatter_y_ax_id}"/>) <>
      ~s(</c:bubbleChart>)
  end

  # -- Data Labels --

  defp data_labels_xml([]), do: ""

  defp data_labels_xml(labels) when is_list(labels) do
    # Support both simple atom list and keyword opts
    {show_atoms, position, number_format} = parse_data_labels(labels)

    show_val =
      if :value in show_atoms, do: ~s(<c:showVal val="1"/>), else: ~s(<c:showVal val="0"/>)

    show_cat =
      if :category in show_atoms,
        do: ~s(<c:showCatName val="1"/>),
        else: ~s(<c:showCatName val="0"/>)

    show_ser =
      if :series in show_atoms,
        do: ~s(<c:showSerName val="1"/>),
        else: ~s(<c:showSerName val="0"/>)

    show_pct =
      if :percent in show_atoms,
        do: ~s(<c:showPercent val="1"/>),
        else: ~s(<c:showPercent val="0"/>)

    pos_xml = dlbl_position_xml(position)
    num_fmt_xml = dlbl_num_fmt_xml(number_format)

    ~s(<c:dLbls>) <>
      num_fmt_xml <>
      pos_xml <>
      show_val <>
      show_cat <>
      show_ser <>
      show_pct <>
      ~s(<c:showLegendKey val="0"/>) <>
      ~s(</c:dLbls>)
  end

  defp parse_data_labels(labels) do
    if Keyword.keyword?(labels) and Keyword.has_key?(labels, :show) do
      {Keyword.get(labels, :show, []), Keyword.get(labels, :position),
       Keyword.get(labels, :number_format)}
    else
      {labels, nil, nil}
    end
  end

  defp dlbl_position_xml(nil), do: ""

  defp dlbl_position_xml(position) do
    val =
      case position do
        :center -> "ctr"
        :inside_end -> "inEnd"
        :inside_base -> "inBase"
        :outside_end -> "outEnd"
        :top -> "t"
        :bottom -> "b"
        :left -> "l"
        :right -> "r"
        :best_fit -> "bestFit"
      end

    ~s(<c:dLblPos val="#{val}"/>)
  end

  defp dlbl_num_fmt_xml(nil), do: ""

  defp dlbl_num_fmt_xml(fmt) do
    ~s(<c:numFmt formatCode="#{Builder.escape(fmt)}" sourceLinked="0"/>)
  end

  defp overlap_xml(%{overlap: nil}), do: ""
  defp overlap_xml(%{overlap: val}), do: ~s(<c:overlap val="#{val}"/>)

  # -- Series --

  defp series_xml(chart) do
    config = ChartType.config(chart.chart_type)
    chart_data = chart.chart_data

    chart_data.series
    |> Enum.map(fn series -> single_series_xml(config, chart_data, series) end)
    |> Enum.join()
  end

  defp single_series_xml(config, %ChartData{} = chart_data, series) do
    marker_xml = cat_marker_xml(config, series)
    smooth_xml = cat_smooth_xml(config)
    invert_xml = invert_if_negative_xml(config)
    explosion_xml = explosion_xml(config)
    color_xml = series_color_xml(config, series)
    dpt_xml = data_points_xml(series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels)

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      invert_xml <>
      explosion_xml <>
      marker_xml <>
      dpt_xml <>
      series_dlbls_xml <>
      cat_xml(chart_data) <>
      val_xml(chart_data, series) <>
      smooth_xml <>
      ~s(</c:ser>)
  end

  defp single_series_xml(config, %XyChartData{} = chart_data, series) do
    marker_xml = xy_marker_xml(config, series)
    smooth_xml = xy_smooth_xml(config)
    no_line_xml = no_line_xml(config, series)
    color_xml = series_color_xml(config, series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels)

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      no_line_xml <>
      marker_xml <>
      series_dlbls_xml <>
      x_val_xml(chart_data, series) <>
      y_val_xml(chart_data, series) <>
      smooth_xml <>
      ~s(</c:ser>)
  end

  defp single_series_xml(config, %BubbleChartData{} = chart_data, series) do
    color_xml = series_color_xml(config, series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels)
    bubble_3d_val = if config[:bubble_3d], do: "1", else: "0"

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      ~s(<c:invertIfNegative val="0"/>) <>
      series_dlbls_xml <>
      x_val_xml(chart_data, series) <>
      y_val_xml(chart_data, series) <>
      bubble_size_xml(chart_data, series) <>
      ~s(<c:bubble3D val="#{bubble_3d_val}"/>) <>
      ~s(</c:ser>)
  end

  # -- Marker helpers for category-based charts --

  defp cat_marker_xml(config, series) do
    cond do
      series.marker ->
        series_marker_xml(series.marker)

      match?(%{element: "c:lineChart", show_marker: false}, config) ->
        ~s(<c:marker><c:symbol val="none"/></c:marker>)

      match?(%{element: "c:radarChart", hide_marker: true}, config) ->
        ~s(<c:marker><c:symbol val="none"/></c:marker>)

      true ->
        ""
    end
  end

  defp cat_smooth_xml(%{element: "c:lineChart"}), do: ~s(<c:smooth val="0"/>)
  defp cat_smooth_xml(%{element: "c:radarChart"}), do: ~s(<c:smooth val="0"/>)
  defp cat_smooth_xml(_), do: ""

  # -- Marker/smooth helpers for XY charts --

  defp xy_marker_xml(config, series) do
    cond do
      series.marker ->
        series_marker_xml(series.marker)

      config[:hide_marker] == true ->
        ~s(<c:marker><c:symbol val="none"/></c:marker>)

      true ->
        ""
    end
  end

  defp xy_smooth_xml(%{scatter_style: "smoothMarker"}), do: ~s(<c:smooth val="1"/>)
  defp xy_smooth_xml(_), do: ~s(<c:smooth val="0"/>)

  defp no_line_xml(%{no_line: true}, %{color: nil, pattern: nil}) do
    ~s(<c:spPr><a:ln><a:noFill/></a:ln></c:spPr>)
  end

  defp no_line_xml(_, _), do: ""

  # -- Invert/explosion helpers --

  defp invert_if_negative_xml(%{element: "c:barChart"}),
    do: ~s(<c:invertIfNegative val="0"/>)

  defp invert_if_negative_xml(_), do: ""

  defp explosion_xml(%{explosion: val}) when is_integer(val),
    do: ~s(<c:explosion val="#{val}"/>)

  defp explosion_xml(_), do: ""

  defp series_color_xml(_config, %{color: nil, pattern: nil}), do: ""

  defp series_color_xml(_config, %{pattern: pattern}) when not is_nil(pattern) do
    prst = Pattern.preset(pattern[:type])
    fg = Keyword.get(pattern, :foreground, "000000")
    bg = Keyword.get(pattern, :background, "FFFFFF")

    ~s(<c:spPr>) <>
      ~s(<a:pattFill prst="#{prst}">) <>
      ~s(<a:fgClr><a:srgbClr val="#{fg}"/></a:fgClr>) <>
      ~s(<a:bgClr><a:srgbClr val="#{bg}"/></a:bgClr>) <>
      ~s(</a:pattFill>) <>
      ~s(</c:spPr>)
  end

  defp series_color_xml(%{element: "c:lineChart"}, %{color: color}) do
    ~s(<c:spPr><a:ln><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></a:ln></c:spPr>)
  end

  defp series_color_xml(_config, %{color: color}) do
    ~s(<c:spPr><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></c:spPr>)
  end

  # -- Per-point formatting --

  defp data_points_xml(%{point_colors: pc, point_formats: pf})
       when pc == %{} and pf == %{},
       do: ""

  defp data_points_xml(%{point_colors: point_colors, point_formats: point_formats}) do
    # Merge point_colors (shorthand) and point_formats into a unified map
    merged =
      Enum.reduce(point_colors, %{}, fn {idx, color}, acc ->
        Map.put(acc, idx, Keyword.merge(Map.get(acc, idx, []), fill: color))
      end)

    merged =
      Enum.reduce(point_formats, merged, fn {idx, fmt}, acc ->
        Map.update(acc, idx, fmt, fn existing -> Keyword.merge(existing, fmt) end)
      end)

    merged
    |> Enum.sort_by(fn {idx, _} -> idx end)
    |> Enum.map(fn {idx, opts} ->
      fill_val = Keyword.get(opts, :fill)
      line_val = Keyword.get(opts, :line)

      fill_xml = if fill_val, do: Drawing.fill_xml(fill_val), else: ""
      line_xml = if line_val, do: Drawing.line_xml(line_val), else: ""

      ~s(<c:dPt>) <>
        ~s(<c:idx val="#{idx}"/>) <>
        ~s(<c:spPr>#{fill_xml}#{line_xml}</c:spPr>) <>
        ~s(</c:dPt>)
    end)
    |> Enum.join()
  end

  # -- Per-point data label overrides --

  defp series_data_labels_xml(nil), do: ""
  defp series_data_labels_xml(dl) when dl == %{}, do: ""

  defp series_data_labels_xml(data_labels) when is_map(data_labels) do
    entries =
      data_labels
      |> Enum.sort_by(fn {idx, _} -> idx end)
      |> Enum.map(fn {idx, opts} -> single_dlbl_xml(idx, opts) end)
      |> Enum.join()

    ~s(<c:dLbls>#{entries}</c:dLbls>)
  end

  defp single_dlbl_xml(idx, opts) do
    show_atoms = Keyword.get(opts, :show, [])
    position = Keyword.get(opts, :position)
    number_format = Keyword.get(opts, :number_format)

    num_fmt_xml = dlbl_num_fmt_xml(number_format)
    pos_xml = dlbl_position_xml(position)

    show_val =
      if :value in show_atoms, do: ~s(<c:showVal val="1"/>), else: ~s(<c:showVal val="0"/>)

    show_cat =
      if :category in show_atoms,
        do: ~s(<c:showCatName val="1"/>),
        else: ~s(<c:showCatName val="0"/>)

    show_ser =
      if :series in show_atoms,
        do: ~s(<c:showSerName val="1"/>),
        else: ~s(<c:showSerName val="0"/>)

    show_pct =
      if :percent in show_atoms,
        do: ~s(<c:showPercent val="1"/>),
        else: ~s(<c:showPercent val="0"/>)

    ~s(<c:dLbl>) <>
      ~s(<c:idx val="#{idx}"/>) <>
      num_fmt_xml <>
      pos_xml <>
      show_val <>
      show_cat <>
      show_ser <>
      show_pct <>
      ~s(<c:showLegendKey val="0"/>) <>
      ~s(</c:dLbl>)
  end

  # -- tx_xml dispatches on data type --

  defp tx_xml(%ChartData{} = chart_data, series) do
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

  defp tx_xml(%XyChartData{} = chart_data, series) do
    name_ref = XyChartData.series_name_ref(chart_data, series)
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

  defp tx_xml(%BubbleChartData{} = chart_data, series) do
    name_ref = BubbleChartData.series_name_ref(chart_data, series)
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

  # -- XY data elements (scatter / bubble) --

  defp x_val_xml(%XyChartData{} = chart_data, series) do
    ref = XyChartData.series_x_values_ref(chart_data, series)
    num_ref_xml("c:xVal", ref, series.x_values)
  end

  defp x_val_xml(%BubbleChartData{} = chart_data, series) do
    ref = BubbleChartData.series_x_values_ref(chart_data, series)
    num_ref_xml("c:xVal", ref, series.x_values)
  end

  defp y_val_xml(%XyChartData{} = chart_data, series) do
    ref = XyChartData.series_y_values_ref(chart_data, series)
    num_ref_xml("c:yVal", ref, series.y_values)
  end

  defp y_val_xml(%BubbleChartData{} = chart_data, series) do
    ref = BubbleChartData.series_y_values_ref(chart_data, series)
    num_ref_xml("c:yVal", ref, series.y_values)
  end

  defp bubble_size_xml(chart_data, series) do
    ref = BubbleChartData.series_bubble_sizes_ref(chart_data, series)
    num_ref_xml("c:bubbleSize", ref, series.bubble_sizes)
  end

  defp num_ref_xml(element, ref, values) do
    count = length(values)

    pts =
      values
      |> Enum.with_index()
      |> Enum.map(fn {val, idx} ->
        ~s(<c:pt idx="#{idx}"><c:v>#{val}</c:v></c:pt>)
      end)
      |> Enum.join()

    ~s(<#{element}>) <>
      ~s(<c:numRef>) <>
      ~s(<c:f>#{ref}</c:f>) <>
      ~s(<c:numCache>) <>
      ~s(<c:formatCode>General</c:formatCode>) <>
      ~s(<c:ptCount val="#{count}"/>) <>
      pts <>
      ~s(</c:numCache>) <>
      ~s(</c:numRef>) <>
      ~s(</#{element}>)
  end

  # -- Axes --

  defp axes_xml(_chart, %{has_axes: false}), do: ""

  defp axes_xml(chart, %{element: "c:lineChart"}) do
    cat_axis_xml(chart, @line_cat_ax_id, @line_val_ax_id) <>
      val_ax_xml(chart, @line_val_ax_id, @line_cat_ax_id)
  end

  defp axes_xml(chart, %{element: "c:areaChart"}) do
    cat_axis_xml(chart, @area_cat_ax_id, @area_val_ax_id) <>
      val_ax_xml(chart, @area_val_ax_id, @area_cat_ax_id)
  end

  defp axes_xml(chart, %{element: "c:radarChart"}) do
    cat_axis_xml(chart, @radar_cat_ax_id, @radar_val_ax_id) <>
      val_ax_xml(chart, @radar_val_ax_id, @radar_cat_ax_id)
  end

  defp axes_xml(chart, %{element: "c:scatterChart"}) do
    val_ax_xml(chart, @scatter_x_ax_id, @scatter_y_ax_id, "b", cross_between: "midCat") <>
      val_ax_xml(chart, @scatter_y_ax_id, @scatter_x_ax_id, "l", cross_between: "midCat")
  end

  defp axes_xml(chart, %{element: "c:bubbleChart"}) do
    val_ax_xml(chart, @scatter_x_ax_id, @scatter_y_ax_id, "b", cross_between: "midCat") <>
      val_ax_xml(chart, @scatter_y_ax_id, @scatter_x_ax_id, "l", cross_between: "midCat")
  end

  defp axes_xml(chart, _config) do
    cat_axis_xml(chart, @cat_ax_id, @val_ax_id) <>
      val_ax_xml(chart, @val_ax_id, @cat_ax_id)
  end

  # Dispatch between catAx and dateAx based on category_axis[:type]
  defp cat_axis_xml(chart, ax_id, cross_ax_id) do
    axis_opts = chart.category_axis || []

    case Keyword.get(axis_opts, :type) do
      :date -> date_ax_xml(chart, ax_id, cross_ax_id)
      _ -> cat_ax_xml(chart, ax_id, cross_ax_id)
    end
  end

  defp cat_ax_xml(chart, ax_id, cross_ax_id) do
    pos = ChartType.cat_ax_pos(chart.chart_type)
    axis_opts = chart.category_axis || []
    axis_title = Keyword.get(axis_opts, :title)
    crosses = Keyword.get(axis_opts, :crosses, :auto_zero)
    label_rotation = Keyword.get(axis_opts, :label_rotation)
    reverse = Keyword.get(axis_opts, :reverse, false)
    visible = Keyword.get(axis_opts, :visible, true)
    major_tick = Keyword.get(axis_opts, :major_tick_mark, :out)
    minor_tick = Keyword.get(axis_opts, :minor_tick_mark, :none)

    orientation = if reverse, do: "maxMin", else: "minMax"
    delete_val = if visible, do: "0", else: "1"

    ~s(<c:catAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      ~s(<c:scaling><c:orientation val="#{orientation}"/></c:scaling>) <>
      ~s(<c:delete val="#{delete_val}"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      axis_title_xml(axis_title) <>
      ~s(<c:majorTickMark val="#{tick_mark_value(major_tick)}"/>) <>
      ~s(<c:minorTickMark val="#{tick_mark_value(minor_tick)}"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      crosses_xml(crosses) <>
      ~s(<c:auto val="1"/>) <>
      ~s(<c:lblAlgn val="ctr"/>) <>
      ~s(<c:lblOffset val="100"/>) <>
      ~s(<c:noMultiLvlLbl val="0"/>) <>
      label_rotation_xml(label_rotation) <>
      ~s(</c:catAx>)
  end

  defp date_ax_xml(chart, ax_id, cross_ax_id) do
    pos = ChartType.cat_ax_pos(chart.chart_type)
    axis_opts = chart.category_axis || []
    axis_title = Keyword.get(axis_opts, :title)
    crosses = Keyword.get(axis_opts, :crosses, :auto_zero)
    label_rotation = Keyword.get(axis_opts, :label_rotation)
    reverse = Keyword.get(axis_opts, :reverse, false)
    visible = Keyword.get(axis_opts, :visible, true)
    major_tick = Keyword.get(axis_opts, :major_tick_mark, :out)
    minor_tick = Keyword.get(axis_opts, :minor_tick_mark, :none)
    base_time_unit = Keyword.get(axis_opts, :base_time_unit)
    major_time_unit = Keyword.get(axis_opts, :major_time_unit)
    minor_time_unit = Keyword.get(axis_opts, :minor_time_unit)
    major_unit = Keyword.get(axis_opts, :major_unit)
    minor_unit = Keyword.get(axis_opts, :minor_unit)

    orientation = if reverse, do: "maxMin", else: "minMax"
    delete_val = if visible, do: "0", else: "1"

    base_xml =
      if base_time_unit,
        do: ~s(<c:baseTimeUnit val="#{time_unit_value(base_time_unit)}"/>),
        else: ""

    major_time_xml =
      if major_time_unit,
        do: ~s(<c:majorTimeUnit val="#{time_unit_value(major_time_unit)}"/>),
        else: ""

    minor_time_xml =
      if minor_time_unit,
        do: ~s(<c:minorTimeUnit val="#{time_unit_value(minor_time_unit)}"/>),
        else: ""

    major_unit_xml = if major_unit, do: ~s(<c:majorUnit val="#{major_unit}"/>), else: ""
    minor_unit_xml = if minor_unit, do: ~s(<c:minorUnit val="#{minor_unit}"/>), else: ""

    ~s(<c:dateAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      ~s(<c:scaling><c:orientation val="#{orientation}"/></c:scaling>) <>
      ~s(<c:delete val="#{delete_val}"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      axis_title_xml(axis_title) <>
      ~s(<c:majorTickMark val="#{tick_mark_value(major_tick)}"/>) <>
      ~s(<c:minorTickMark val="#{tick_mark_value(minor_tick)}"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      crosses_xml(crosses) <>
      base_xml <>
      major_unit_xml <>
      major_time_xml <>
      minor_unit_xml <>
      minor_time_xml <>
      label_rotation_xml(label_rotation) <>
      ~s(</c:dateAx>)
  end

  defp time_unit_value(:days), do: "days"
  defp time_unit_value(:months), do: "months"
  defp time_unit_value(:years), do: "years"

  # Standard val_ax_xml using chart_type for axis positions
  defp val_ax_xml(chart, ax_id, cross_ax_id) do
    pos = ChartType.val_ax_pos(chart.chart_type)
    do_val_ax_xml(chart, ax_id, cross_ax_id, pos, [])
  end

  # Explicit position val_ax_xml for scatter/bubble (two valAx axes)
  defp val_ax_xml(chart, ax_id, cross_ax_id, pos, opts) do
    do_val_ax_xml(chart, ax_id, cross_ax_id, pos, opts)
  end

  defp do_val_ax_xml(chart, ax_id, cross_ax_id, pos, opts) do
    axis_opts = chart.value_axis || []
    axis_title = Keyword.get(axis_opts, :title)
    num_fmt = Keyword.get(axis_opts, :number_format)
    gridlines = Keyword.get(axis_opts, :major_gridlines, true)
    minor_gridlines = Keyword.get(axis_opts, :minor_gridlines, false)
    min_val = Keyword.get(axis_opts, :min)
    max_val = Keyword.get(axis_opts, :max)
    major_unit = Keyword.get(axis_opts, :major_unit)
    minor_unit = Keyword.get(axis_opts, :minor_unit)
    crosses = Keyword.get(axis_opts, :crosses, :auto_zero)
    label_rotation = Keyword.get(axis_opts, :label_rotation)
    reverse = Keyword.get(axis_opts, :reverse, false)
    visible = Keyword.get(axis_opts, :visible, true)
    major_tick = Keyword.get(axis_opts, :major_tick_mark, :out)
    minor_tick = Keyword.get(axis_opts, :minor_tick_mark, :none)

    scaling_xml = val_scaling_xml(min_val, max_val, reverse)
    gridlines_xml = if gridlines, do: ~s(<c:majorGridlines/>), else: ""
    minor_gridlines_xml = if minor_gridlines, do: ~s(<c:minorGridlines/>), else: ""
    num_fmt_xml = val_num_fmt_xml(num_fmt)
    major_unit_xml = if major_unit, do: ~s(<c:majorUnit val="#{major_unit}"/>), else: ""
    minor_unit_xml = if minor_unit, do: ~s(<c:minorUnit val="#{minor_unit}"/>), else: ""
    delete_val = if visible, do: "0", else: "1"

    cross_between_xml =
      case Keyword.get(opts, :cross_between) do
        nil -> ""
        val -> ~s(<c:crossBetween val="#{val}"/>)
      end

    ~s(<c:valAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      scaling_xml <>
      ~s(<c:delete val="#{delete_val}"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      gridlines_xml <>
      minor_gridlines_xml <>
      axis_title_xml(axis_title) <>
      num_fmt_xml <>
      ~s(<c:majorTickMark val="#{tick_mark_value(major_tick)}"/>) <>
      ~s(<c:minorTickMark val="#{tick_mark_value(minor_tick)}"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      crosses_xml(crosses) <>
      cross_between_xml <>
      major_unit_xml <>
      minor_unit_xml <>
      label_rotation_xml(label_rotation) <>
      ~s(</c:valAx>)
  end

  defp crosses_xml(:auto_zero), do: ~s(<c:crosses val="autoZero"/>)
  defp crosses_xml(:min), do: ~s(<c:crosses val="min"/>)
  defp crosses_xml(:max), do: ~s(<c:crosses val="max"/>)

  defp crosses_xml(value) when is_number(value),
    do: ~s(<c:crossesAt val="#{value}"/>)

  defp val_scaling_xml(min_val, max_val, reverse) do
    orientation = if reverse, do: "maxMin", else: "minMax"
    min_xml = if min_val, do: ~s(<c:min val="#{min_val}"/>), else: ""
    max_xml = if max_val, do: ~s(<c:max val="#{max_val}"/>), else: ""
    ~s(<c:scaling><c:orientation val="#{orientation}"/>#{min_xml}#{max_xml}</c:scaling>)
  end

  defp val_num_fmt_xml(nil), do: ""

  defp val_num_fmt_xml(fmt) do
    ~s(<c:numFmt formatCode="#{Builder.escape(fmt)}" sourceLinked="0"/>)
  end

  defp axis_title_xml(nil), do: ""

  defp axis_title_xml(title) when is_binary(title) do
    escaped = Builder.escape(title)

    ~s(<c:title>) <>
      ~s(<c:tx><c:rich>) <>
      ~s(<a:bodyPr/><a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escaped}</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>) <>
      ~s(</c:rich></c:tx>) <>
      ~s(<c:overlay val="0"/>) <>
      ~s(</c:title>)
  end

  defp axis_title_xml(opts) when is_list(opts) do
    text = Keyword.fetch!(opts, :text)
    escaped = Builder.escape(text)
    rpr_xml = font_rpr_xml(opts)

    ~s(<c:title>) <>
      ~s(<c:tx><c:rich>) <>
      ~s(<a:bodyPr/><a:lstStyle/>) <>
      ~s(<a:p><a:r>#{rpr_xml}<a:t>#{escaped}</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>) <>
      ~s(</c:rich></c:tx>) <>
      ~s(<c:overlay val="0"/>) <>
      ~s(</c:title>)
  end

  defp label_rotation_xml(nil), do: ""

  defp label_rotation_xml(degrees) do
    # OOXML rotation is in 1/60000th of a degree
    rot = degrees * 60_000

    ~s(<c:txPr><a:bodyPr rot="#{rot}"/><a:lstStyle/>) <>
      ~s(<a:p><a:pPr><a:defRPr/></a:pPr><a:endParaRPr lang="en-US"/></a:p></c:txPr>)
  end

  defp font_rpr_xml(opts) do
    attrs = font_rpr_attrs(opts)
    children = font_rpr_children(opts)

    if children == "" do
      ~s(<a:rPr #{attrs}/>)
    else
      ~s(<a:rPr #{attrs}>#{children}</a:rPr>)
    end
  end

  defp font_rpr_attrs(opts) do
    attrs = [~s(lang="en-US")]
    font_size = Keyword.get(opts, :font_size)
    bold = Keyword.get(opts, :bold)
    italic = Keyword.get(opts, :italic)

    attrs = if font_size, do: attrs ++ [~s(sz="#{font_size * 100}")], else: attrs
    attrs = if bold, do: attrs ++ [~s(b="1")], else: attrs
    attrs = if italic, do: attrs ++ [~s(i="1")], else: attrs
    attrs = attrs ++ [~s(dirty="0")]
    Enum.join(attrs, " ")
  end

  defp font_rpr_children(opts) do
    color = Keyword.get(opts, :color)
    font = Keyword.get(opts, :font)
    color_xml = if color, do: ~s(<a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>), else: ""
    font_xml = if font, do: ~s(<a:latin typeface="#{font}"/>), else: ""
    color_xml <> font_xml
  end

  defp series_marker_xml(opts) when is_list(opts) do
    style = Keyword.get(opts, :style)
    size = Keyword.get(opts, :size)
    fill = Keyword.get(opts, :fill)
    line = Keyword.get(opts, :line)

    symbol_xml = if style, do: ~s(<c:symbol val="#{marker_symbol(style)}"/>), else: ""
    size_xml = if size, do: ~s(<c:size val="#{size}"/>), else: ""

    sp_pr_xml =
      if fill || line do
        fill_xml = if fill, do: Drawing.fill_xml(fill), else: ""
        line_xml = if line, do: Drawing.line_xml(line), else: ""
        ~s(<c:spPr>#{fill_xml}#{line_xml}</c:spPr>)
      else
        ""
      end

    ~s(<c:marker>#{symbol_xml}#{size_xml}#{sp_pr_xml}</c:marker>)
  end

  defp marker_symbol(:circle), do: "circle"
  defp marker_symbol(:square), do: "square"
  defp marker_symbol(:diamond), do: "diamond"
  defp marker_symbol(:triangle), do: "triangle"
  defp marker_symbol(:star), do: "star"
  defp marker_symbol(:x), do: "x"
  defp marker_symbol(:plus), do: "plus"
  defp marker_symbol(:dash), do: "dash"
  defp marker_symbol(:dot), do: "dot"
  defp marker_symbol(:none), do: "none"

  defp tick_mark_value(:out), do: "out"
  defp tick_mark_value(:in), do: "in"
  defp tick_mark_value(:cross), do: "cross"
  defp tick_mark_value(:none), do: "none"

  # -- Combo Chart --

  defp combo_chart_space_xml(chart) do
    ns_c = Constants.ns(:c)
    ns_a = Constants.ns(:a)
    ns_r = Constants.ns(:r)

    has_secondary = Enum.any?(chart.combo.plots, & &1.secondary_axis)

    ~s(<c:chartSpace xmlns:c="#{ns_c}" xmlns:a="#{ns_a}" xmlns:r="#{ns_r}">) <>
      ~s(<c:date1904 val="0"/>) <>
      ~s(<c:chart>) <>
      title_xml(chart.title) <>
      ~s(<c:plotArea>) <>
      combo_plots_xml(chart) <>
      combo_axes_xml(chart, has_secondary) <>
      ~s(</c:plotArea>) <>
      legend_xml(chart.legend) <>
      ~s(<c:dispBlanksAs val="gap"/>) <>
      ~s(</c:chart>) <>
      txpr_xml() <>
      ~s(<c:externalData r:id="rId1"><c:autoUpdate val="0"/></c:externalData>) <>
      ~s(</c:chartSpace>)
  end

  defp combo_plots_xml(chart) do
    # Track global series index across plots
    {plots_xml, _} =
      Enum.reduce(chart.combo.plots, {"", 0}, fn plot, {xml_acc, global_offset} ->
        config = ChartType.config(plot.chart_type)
        chart_data = chart.combo.chart_data

        selected_series =
          Enum.map(plot.series_indices, fn idx ->
            Enum.at(chart_data.series, idx)
          end)

        {cat_ax_id, val_ax_id} = combo_axis_ids(plot)

        plot_xml =
          combo_single_plot_xml(
            config,
            chart_data,
            selected_series,
            cat_ax_id,
            val_ax_id,
            plot.series_indices,
            chart.data_labels
          )

        {xml_acc <> plot_xml, global_offset + length(selected_series)}
      end)

    plots_xml
  end

  defp combo_single_plot_xml(
         %{element: "c:barChart"} = config,
         chart_data,
         series_list,
         cat_ax_id,
         val_ax_id,
         global_indices,
         data_labels
       ) do
    series_xml =
      series_list
      |> Enum.zip(global_indices)
      |> Enum.map(fn {series, global_idx} ->
        combo_series_xml(config, chart_data, series, global_idx)
      end)
      |> Enum.join()

    ~s(<c:barChart>) <>
      ~s(<c:barDir val="#{config.bar_dir}"/>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      series_xml <>
      data_labels_xml(data_labels) <>
      overlap_xml(config) <>
      ~s(<c:axId val="#{cat_ax_id}"/>) <>
      ~s(<c:axId val="#{val_ax_id}"/>) <>
      ~s(</c:barChart>)
  end

  defp combo_single_plot_xml(
         %{element: "c:lineChart"} = config,
         chart_data,
         series_list,
         cat_ax_id,
         val_ax_id,
         global_indices,
         data_labels
       ) do
    series_xml =
      series_list
      |> Enum.zip(global_indices)
      |> Enum.map(fn {series, global_idx} ->
        combo_series_xml(config, chart_data, series, global_idx)
      end)
      |> Enum.join()

    ~s(<c:lineChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml <>
      data_labels_xml(data_labels) <>
      ~s(<c:marker val="1"/>) <>
      ~s(<c:smooth val="0"/>) <>
      ~s(<c:axId val="#{cat_ax_id}"/>) <>
      ~s(<c:axId val="#{val_ax_id}"/>) <>
      ~s(</c:lineChart>)
  end

  defp combo_single_plot_xml(
         %{element: "c:areaChart"} = config,
         chart_data,
         series_list,
         cat_ax_id,
         val_ax_id,
         global_indices,
         data_labels
       ) do
    series_xml =
      series_list
      |> Enum.zip(global_indices)
      |> Enum.map(fn {series, global_idx} ->
        combo_series_xml(config, chart_data, series, global_idx)
      end)
      |> Enum.join()

    ~s(<c:areaChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      ~s(<c:varyColors val="0"/>) <>
      series_xml <>
      data_labels_xml(data_labels) <>
      ~s(<c:axId val="#{cat_ax_id}"/>) <>
      ~s(<c:axId val="#{val_ax_id}"/>) <>
      ~s(</c:areaChart>)
  end

  defp combo_series_xml(config, chart_data, series, global_idx) do
    marker_xml = cat_marker_xml(config, series)
    smooth_xml = cat_smooth_xml(config)
    invert_xml = invert_if_negative_xml(config)
    color_xml = series_color_xml(config, series)
    dpt_xml = data_points_xml(series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels)

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{global_idx}"/>) <>
      ~s(<c:order val="#{global_idx}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      invert_xml <>
      marker_xml <>
      dpt_xml <>
      series_dlbls_xml <>
      cat_xml(chart_data) <>
      val_xml(chart_data, series) <>
      smooth_xml <>
      ~s(</c:ser>)
  end

  defp combo_axes_xml(chart, has_secondary) do
    cat_ax = combo_cat_ax_xml(chart, @combo_cat_ax_id, @combo_val_ax_id)

    primary_val_ax =
      combo_val_ax_xml(chart, chart.value_axis, @combo_val_ax_id, @combo_cat_ax_id, "l")

    secondary_val_ax =
      if has_secondary do
        combo_val_ax_xml(
          chart,
          chart.secondary_value_axis,
          @combo_secondary_val_ax_id,
          @combo_cat_ax_id,
          "r"
        )
      else
        ""
      end

    cat_ax <> primary_val_ax <> secondary_val_ax
  end

  defp combo_cat_ax_xml(chart, ax_id, cross_ax_id) do
    axis_opts = chart.category_axis || []
    axis_title = Keyword.get(axis_opts, :title)
    crosses = Keyword.get(axis_opts, :crosses, :auto_zero)
    label_rotation = Keyword.get(axis_opts, :label_rotation)
    reverse = Keyword.get(axis_opts, :reverse, false)
    visible = Keyword.get(axis_opts, :visible, true)

    # Determine position from first plot's chart type
    first_type = hd(chart.combo.plots).chart_type
    pos = ChartType.cat_ax_pos(first_type)
    orientation = if reverse, do: "maxMin", else: "minMax"
    delete_val = if visible, do: "0", else: "1"

    ~s(<c:catAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      ~s(<c:scaling><c:orientation val="#{orientation}"/></c:scaling>) <>
      ~s(<c:delete val="#{delete_val}"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      axis_title_xml(axis_title) <>
      ~s(<c:majorTickMark val="out"/>) <>
      ~s(<c:minorTickMark val="none"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      crosses_xml(crosses) <>
      ~s(<c:auto val="1"/>) <>
      ~s(<c:lblAlgn val="ctr"/>) <>
      ~s(<c:lblOffset val="100"/>) <>
      ~s(<c:noMultiLvlLbl val="0"/>) <>
      label_rotation_xml(label_rotation) <>
      ~s(</c:catAx>)
  end

  defp combo_val_ax_xml(chart, axis_opts, ax_id, cross_ax_id, pos) do
    axis_opts = axis_opts || []
    axis_title = Keyword.get(axis_opts, :title)
    num_fmt = Keyword.get(axis_opts, :number_format)
    gridlines = Keyword.get(axis_opts, :major_gridlines, pos == "l")
    minor_gridlines = Keyword.get(axis_opts, :minor_gridlines, false)
    min_val = Keyword.get(axis_opts, :min)
    max_val = Keyword.get(axis_opts, :max)
    major_unit = Keyword.get(axis_opts, :major_unit)
    minor_unit = Keyword.get(axis_opts, :minor_unit)
    crosses = Keyword.get(axis_opts, :crosses, :auto_zero)
    label_rotation = Keyword.get(axis_opts, :label_rotation)
    reverse = Keyword.get(axis_opts, :reverse, false)
    visible = Keyword.get(axis_opts, :visible, true)

    _ = chart

    scaling_xml = val_scaling_xml(min_val, max_val, reverse)
    gridlines_xml = if gridlines, do: ~s(<c:majorGridlines/>), else: ""
    minor_gridlines_xml = if minor_gridlines, do: ~s(<c:minorGridlines/>), else: ""
    num_fmt_xml = val_num_fmt_xml(num_fmt)
    major_unit_xml = if major_unit, do: ~s(<c:majorUnit val="#{major_unit}"/>), else: ""
    minor_unit_xml = if minor_unit, do: ~s(<c:minorUnit val="#{minor_unit}"/>), else: ""
    delete_val = if visible, do: "0", else: "1"

    # Secondary axis crosses at max to avoid overlapping
    crosses_out =
      if pos == "r" and crosses == :auto_zero do
        crosses_xml(:max)
      else
        crosses_xml(crosses)
      end

    ~s(<c:valAx>) <>
      ~s(<c:axId val="#{ax_id}"/>) <>
      scaling_xml <>
      ~s(<c:delete val="#{delete_val}"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      gridlines_xml <>
      minor_gridlines_xml <>
      axis_title_xml(axis_title) <>
      num_fmt_xml <>
      ~s(<c:majorTickMark val="out"/>) <>
      ~s(<c:minorTickMark val="none"/>) <>
      ~s(<c:tickLblPos val="nextTo"/>) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      crosses_out <>
      major_unit_xml <>
      minor_unit_xml <>
      label_rotation_xml(label_rotation) <>
      ~s(</c:valAx>)
  end

  defp combo_axis_ids(%ComboChart.PlotSpec{secondary_axis: true}) do
    {@combo_cat_ax_id, @combo_secondary_val_ax_id}
  end

  defp combo_axis_ids(%ComboChart.PlotSpec{secondary_axis: false}) do
    {@combo_cat_ax_id, @combo_val_ax_id}
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
