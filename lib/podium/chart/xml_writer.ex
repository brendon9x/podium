defmodule Podium.Chart.XmlWriter do
  @moduledoc false

  alias Podium.Chart
  alias Podium.Chart.{ChartData, ChartType}
  alias Podium.OPC.Constants
  alias Podium.Pattern
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

  defp title_xml(opts) when is_list(opts) do
    text = Keyword.fetch!(opts, :text)
    escaped = Builder.escape(text)
    rpr_xml = font_rpr_xml(opts)

    ~s(<c:title>) <>
      ~s(<c:tx><c:rich>) <>
      ~s(<a:bodyPr/><a:lstStyle/>) <>
      ~s(<a:p><a:r>#{rpr_xml}<a:t>#{escaped}</a:t></a:r></a:p>) <>
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

    # Bar/column series default invertIfNegative to true when absent,
    # which can cause fills to render incorrectly. Explicitly disable it.
    invert_xml =
      case config.element do
        "c:barChart" -> ~s(<c:invertIfNegative val="0"/>)
        _ -> ""
      end

    color_xml = series_color_xml(config, series)
    dpt_xml = data_points_xml(series)

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      invert_xml <>
      marker_xml <>
      dpt_xml <>
      cat_xml(chart_data) <>
      val_xml(chart_data, series) <>
      smooth_xml <>
      ~s(</c:ser>)
  end

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

  defp data_points_xml(%{point_colors: pc}) when pc == %{}, do: ""

  defp data_points_xml(%{point_colors: point_colors}) do
    point_colors
    |> Enum.sort_by(fn {idx, _} -> idx end)
    |> Enum.map(fn {idx, color} ->
      ~s(<c:dPt>) <>
        ~s(<c:idx val="#{idx}"/>) <>
        ~s(<c:spPr><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></c:spPr>) <>
        ~s(</c:dPt>)
    end)
    |> Enum.join()
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
    crosses = Keyword.get(axis_opts, :crosses, :auto_zero)
    label_rotation = Keyword.get(axis_opts, :label_rotation)

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
      crosses_xml(crosses) <>
      ~s(<c:auto val="1"/>) <>
      ~s(<c:lblAlgn val="ctr"/>) <>
      ~s(<c:lblOffset val="100"/>) <>
      ~s(<c:noMultiLvlLbl val="0"/>) <>
      label_rotation_xml(label_rotation) <>
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
    crosses = Keyword.get(axis_opts, :crosses, :auto_zero)
    label_rotation = Keyword.get(axis_opts, :label_rotation)

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
      crosses_xml(crosses) <>
      major_unit_xml <>
      label_rotation_xml(label_rotation) <>
      ~s(</c:valAx>)
  end

  defp crosses_xml(:auto_zero), do: ~s(<c:crosses val="autoZero"/>)
  defp crosses_xml(:min), do: ~s(<c:crosses val="min"/>)
  defp crosses_xml(:max), do: ~s(<c:crosses val="max"/>)

  defp crosses_xml(value) when is_number(value),
    do: ~s(<c:crossesAt val="#{value}"/>)

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

  defp axis_title_xml(title) when is_binary(title) do
    escaped = Builder.escape(title)

    ~s(<c:title>) <>
      ~s(<c:tx><c:rich>) <>
      ~s(<a:bodyPr/><a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escaped}</a:t></a:r></a:p>) <>
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
      ~s(<a:p><a:r>#{rpr_xml}<a:t>#{escaped}</a:t></a:r></a:p>) <>
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
