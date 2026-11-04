defmodule Podium.Chart.XmlWriter do
  @moduledoc """
  Chart XML generation for the chart part (`ppt/charts/chartN.xml`).

  Renders the complete chart XML including plot area, series, axes, title,
  legend, and data labels for all supported chart types.
  """

  alias Podium.Chart
  alias Podium.Chart.{BubbleChartData, ChartData, ChartType, ComboChart, XyChartData}
  alias Podium.{Drawing, Text}
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
    Builder.xml_declaration() <> combo_chart_space_xml(titles_follow_text(chart))
  end

  def to_xml(%Chart{} = chart) do
    config = ChartType.config(chart.chart_type)

    Builder.xml_declaration() <>
      chart_space_xml(titles_follow_text(chart), config)
  end

  # PowerPoint does not apply the chart-wide text style (chartSpace txPr) to
  # the chart and axis titles, so :text is written into them, under their
  # own options. Titles keep their own size.
  defp titles_follow_text(%Chart{text: text} = chart) do
    case text |> font_opts() |> Keyword.delete(:font_size) do
      [] ->
        chart

      defaults ->
        %{
          chart
          | title: title_with_defaults(chart.title, defaults),
            category_axis: axis_title_with_defaults(chart.category_axis, defaults),
            value_axis: axis_title_with_defaults(chart.value_axis, defaults),
            secondary_value_axis: axis_title_with_defaults(chart.secondary_value_axis, defaults)
        }
    end
  end

  defp axis_title_with_defaults(nil, _defaults), do: nil

  defp axis_title_with_defaults(axis_opts, defaults) do
    case Keyword.get(axis_opts, :title) do
      nil -> axis_opts
      title -> Keyword.put(axis_opts, :title, title_with_defaults(title, defaults))
    end
  end

  defp title_with_defaults(nil, _defaults), do: nil
  defp title_with_defaults(title, defaults) when is_binary(title), do: [text: title] ++ defaults

  defp title_with_defaults(title, defaults) do
    if Keyword.keyword?(title),
      do: Keyword.merge(defaults, title),
      else: [text: title] ++ defaults
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
      plot_area_layout_xml(chart.plot_area) <>
      plot_xml(chart, config) <>
      axes_xml(chart, config) <>
      sp_pr_xml(chart.plot_area) <>
      ~s(</c:plotArea>) <>
      legend_xml(chart.legend) <>
      ~s(<c:dispBlanksAs val="gap"/>) <>
      ~s(</c:chart>) <>
      chart_area_xml(chart.background) <>
      chart_text_xml(chart.text) <>
      ~s(<c:externalData r:id="rId1"><c:autoUpdate val="0"/></c:externalData>) <>
      ~s(</c:chartSpace>)
  end

  # -- Title --

  defp title_xml(nil), do: ~s(<c:autoTitleDeleted val="1"/>)

  defp title_xml(title) do
    opts = if is_list(title) and Keyword.keyword?(title), do: title, else: []

    ~s(<c:title>) <>
      title_text_xml(title) <>
      manual_layout_xml(opts) <>
      overlay_xml(opts) <>
      title_sp_pr_xml(title) <>
      ~s(</c:title>)
  end

  defp overlay_xml(opts) do
    val = if Keyword.get(opts, :overlay, false), do: "1", else: "0"
    ~s(<c:overlay val="#{val}"/>)
  end

  # A manual position as fractions of the chart frame: :x and :y place the
  # element's top-left corner, :w and :h size it. With no :x it is laid out
  # automatically.
  defp manual_layout_xml(opts, target \\ nil) do
    case Keyword.get(opts, :x) do
      nil ->
        ""

      _ ->
        target_xml =
          if target, do: ~s(<c:layoutTarget val="#{target}"/>), else: ""

        size_xml =
          case {Keyword.get(opts, :w), Keyword.get(opts, :h)} do
            {nil, nil} -> ""
            {w, h} -> ~s(<c:w val="#{w}"/><c:h val="#{h}"/>)
          end

        ~s(<c:layout><c:manualLayout>#{target_xml}) <>
          ~s(<c:xMode val="edge"/><c:yMode val="edge"/>) <>
          ~s(<c:x val="#{Keyword.fetch!(opts, :x)}"/><c:y val="#{Keyword.fetch!(opts, :y)}"/>) <>
          size_xml <> ~s(</c:manualLayout></c:layout>)
    end
  end

  # -- Legend --

  defp legend_xml(nil), do: ""
  defp legend_xml(false), do: ""

  defp legend_xml(position) when position in [:left, :right, :top, :bottom] do
    pos = legend_pos_value(position)
    ~s(<c:legend><c:legendPos val="#{pos}"/><c:overlay val="0"/></c:legend>)
  end

  defp legend_xml(opts) when is_list(opts) do
    pos = legend_pos_value(Keyword.get(opts, :position, :right))

    ~s(<c:legend><c:legendPos val="#{pos}"/>) <>
      manual_layout_xml(opts) <>
      overlay_xml(opts) <>
      sp_pr_xml(opts) <> text_props_xml(font_opts(opts)) <> ~s(</c:legend>)
  end

  defp legend_pos_value(:left), do: "l"
  defp legend_pos_value(:right), do: "r"
  defp legend_pos_value(:top), do: "t"
  defp legend_pos_value(:bottom), do: "b"

  # -- Date1904 --

  defp date1904_xml(%{element: "c:pieChart"}), do: ""
  defp date1904_xml(%{element: "c:doughnutChart"}), do: ""
  defp date1904_xml(_), do: ~s(<c:date1904 val="0"/>)

  # -- Plot --

  defp plot_xml(chart, %{element: "c:barChart"} = config) do
    ~s(<c:barChart>) <>
      ~s(<c:barDir val="#{config.bar_dir}"/>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      bar_vary_colors_xml(chart.vary_by_categories) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      gap_width_xml(chart.gap_width) <>
      overlap_xml(config, chart.overlap) <>
      ~s(<c:axId val="#{@cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@val_ax_id}"/>) <>
      ~s(</c:barChart>)
  end

  defp plot_xml(chart, %{element: "c:lineChart"} = config) do
    ~s(<c:lineChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      vary_colors_xml(chart.vary_by_categories, false) <>
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
      vary_colors_xml(chart.vary_by_categories, true) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(</c:pieChart>)
  end

  defp plot_xml(chart, %{element: "c:areaChart"} = config) do
    ~s(<c:areaChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      vary_colors_xml(chart.vary_by_categories, false) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:axId val="#{@area_cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@area_val_ax_id}"/>) <>
      ~s(</c:areaChart>)
  end

  defp plot_xml(chart, %{element: "c:doughnutChart"}) do
    ~s(<c:doughnutChart>) <>
      vary_colors_xml(chart.vary_by_categories, true) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:firstSliceAng val="0"/>) <>
      ~s(<c:holeSize val="50"/>) <>
      ~s(</c:doughnutChart>)
  end

  defp plot_xml(chart, %{element: "c:radarChart"} = config) do
    ~s(<c:radarChart>) <>
      ~s(<c:radarStyle val="#{config.radar_style}"/>) <>
      vary_colors_xml(chart.vary_by_categories, false) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:axId val="#{@radar_cat_ax_id}"/>) <>
      ~s(<c:axId val="#{@radar_val_ax_id}"/>) <>
      ~s(</c:radarChart>)
  end

  defp plot_xml(chart, %{element: "c:scatterChart"} = config) do
    ~s(<c:scatterChart>) <>
      ~s(<c:scatterStyle val="#{config.scatter_style}"/>) <>
      vary_colors_xml(chart.vary_by_categories, false) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:axId val="#{@scatter_x_ax_id}"/>) <>
      ~s(<c:axId val="#{@scatter_y_ax_id}"/>) <>
      ~s(</c:scatterChart>)
  end

  defp plot_xml(chart, %{element: "c:bubbleChart"}) do
    ~s(<c:bubbleChart>) <>
      vary_colors_xml(chart.vary_by_categories, false) <>
      series_xml(chart) <>
      data_labels_xml(chart.data_labels) <>
      ~s(<c:bubbleScale val="#{chart.bubble_scale || 100}"/>) <>
      ~s(<c:showNegBubbles val="0"/>) <>
      ~s(<c:axId val="#{@scatter_x_ax_id}"/>) <>
      ~s(<c:axId val="#{@scatter_y_ax_id}"/>) <>
      ~s(</c:bubbleChart>)
  end

  # -- Data Labels --

  defp data_labels_xml([]), do: ""

  defp data_labels_xml(labels) when is_list(labels) do
    ~s(<c:dLbls>#{dlbls_group_xml(labels)}</c:dLbls>)
  end

  # The formatting and show flags of a <c:dLbls> or <c:dLbl>, in the CT_DLbls
  # order: numFmt, spPr, txPr, dLblPos, showLegendKey, showVal, showCatName,
  # showSerName, showPercent, showBubbleSize, separator.
  defp dlbls_group_xml(labels) do
    {show, opts} = parse_data_labels(labels)

    dlbl_num_fmt_xml(Keyword.get(opts, :number_format)) <>
      sp_pr_xml(opts) <>
      text_props_xml(font_opts(opts)) <>
      dlbl_position_xml(Keyword.get(opts, :position)) <>
      dlbl_show_flags_xml(show) <>
      dlbl_separator_xml(Keyword.get(opts, :separator))
  end

  defp dlbl_show_flags_xml(show) do
    flag = fn name, atom ->
      val = if atom in show, do: "1", else: "0"
      ~s(<c:#{name} val="#{val}"/>)
    end

    # showBubbleSize is left out unless asked for, as it always has been
    bubble_xml = if :bubble_size in show, do: flag.("showBubbleSize", :bubble_size), else: ""

    flag.("showLegendKey", :legend_key) <>
      flag.("showVal", :value) <>
      flag.("showCatName", :category) <>
      flag.("showSerName", :series) <>
      flag.("showPercent", :percent) <>
      bubble_xml
  end

  defp dlbl_separator_xml(nil), do: ""

  defp dlbl_separator_xml(separator),
    do: ~s(<c:separator>#{Builder.escape(separator)}</c:separator>)

  # A plain list of atoms names what to show. A keyword list carries options,
  # showing values when it does not say what to show.
  defp parse_data_labels(labels) do
    if labels != [] and Keyword.keyword?(labels) do
      {Keyword.get(labels, :show, [:value]), labels}
    else
      {labels, []}
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

  # A given :overlap replaces the chart type's own (100 for stacked bars).
  defp overlap_xml(%{overlap: nil}, nil), do: ""
  defp overlap_xml(%{overlap: val}, nil), do: ~s(<c:overlap val="#{val}"/>)
  defp overlap_xml(_config, val), do: ~s(<c:overlap val="#{val}"/>)

  defp gap_width_xml(nil), do: ""
  defp gap_width_xml(val), do: ~s(<c:gapWidth val="#{val}"/>)

  defp vary_colors_xml(nil, default), do: vary_colors_xml(default, default)
  defp vary_colors_xml(true, _default), do: ~s(<c:varyColors val="1"/>)
  defp vary_colors_xml(false, _default), do: ~s(<c:varyColors val="0"/>)

  # Bar plots have always left varyColors out, which PowerPoint reads as off.
  defp bar_vary_colors_xml(nil), do: ""
  defp bar_vary_colors_xml(vary), do: vary_colors_xml(vary, false)

  # -- Series --

  defp series_xml(chart) do
    config = chart.chart_type |> ChartType.config() |> Map.put(:plot_labels, chart.data_labels)
    chart_data = chart.chart_data

    chart_data.series
    |> Enum.map(fn series -> single_series_xml(config, chart_data, series) end)
    |> Enum.join()
  end

  defp single_series_xml(config, %ChartData{} = chart_data, series) do
    marker_xml = cat_marker_xml(config, series)
    smooth_xml = cat_smooth_xml(config)
    invert_xml = invert_if_negative_xml(config, series)
    explosion_xml = explosion_xml(config)
    color_xml = series_sp_pr_xml(config, series)
    dpt_xml = data_points_xml(config, series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels, config[:plot_labels])

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
    color_xml = series_sp_pr_xml(config, series)
    dpt_xml = data_points_xml(config, series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels, config[:plot_labels])

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      marker_xml <>
      dpt_xml <>
      series_dlbls_xml <>
      x_val_xml(chart_data, series) <>
      y_val_xml(chart_data, series) <>
      smooth_xml <>
      ~s(</c:ser>)
  end

  defp single_series_xml(config, %BubbleChartData{} = chart_data, series) do
    color_xml = series_sp_pr_xml(config, series)
    dpt_xml = data_points_xml(config, series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels, config[:plot_labels])
    bubble_3d_val = if config[:bubble_3d], do: "1", else: "0"

    ~s(<c:ser>) <>
      ~s(<c:idx val="#{series.index}"/>) <>
      ~s(<c:order val="#{series.index}"/>) <>
      tx_xml(chart_data, series) <>
      color_xml <>
      invert_if_negative_xml(config, series) <>
      dpt_xml <>
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
    # A markers-only scatter series draws no line, so its colour goes to the
    # markers, under any fill or line the marker sets itself.
    marker =
      if config[:no_line] and is_binary(series.color) do
        (series.marker || [])
        |> Keyword.put_new(:fill, series.color)
        |> Keyword.put_new(:line, series.color)
      else
        series.marker
      end

    cond do
      marker ->
        series_marker_xml(marker)

      config[:hide_marker] == true ->
        ~s(<c:marker><c:symbol val="none"/></c:marker>)

      true ->
        ""
    end
  end

  defp xy_smooth_xml(%{scatter_style: "smoothMarker"}), do: ~s(<c:smooth val="1"/>)
  defp xy_smooth_xml(_), do: ~s(<c:smooth val="0"/>)

  # -- Invert/explosion helpers --

  # Bar and bubble series (and their points) state invertIfNegative: the
  # schema default is true, which paints a negative bar white.
  defp invert_if_negative_xml(%{element: element}, series)
       when element in ["c:barChart", "c:bubbleChart"] do
    val = if Map.get(series, :invert_if_negative), do: "1", else: "0"
    ~s(<c:invertIfNegative val="#{val}"/>)
  end

  defp invert_if_negative_xml(_config, _series), do: ""

  defp explosion_xml(%{explosion: val}) when is_integer(val),
    do: ~s(<c:explosion val="#{val}"/>)

  defp explosion_xml(_), do: ""

  # The series <c:spPr>, holding its fill and its line. On a line, scatter or
  # (unfilled) radar series :color is the line colour, and a markers-only
  # scatter series draws no line; elsewhere :color is the fill and :line the
  # outline. :fill and :line override :color.
  defp series_sp_pr_xml(config, series) do
    if line_series?(config) do
      line =
        cond do
          series.line -> series.line
          config[:no_line] -> :none
          true -> series.color
        end

      sp_pr_xml(fill: series.fill, line: line)
    else
      sp_pr_xml(fill: series.fill || series.color, line: series.line)
    end
  end

  defp line_series?(%{element: element}) when element in ["c:lineChart", "c:scatterChart"],
    do: true

  defp line_series?(%{element: "c:radarChart", radar_style: "marker"}), do: true
  defp line_series?(_config), do: false

  # -- Per-point formatting --

  defp data_points_xml(_config, %{point_colors: pc, point_formats: pf})
       when pc == %{} and pf == %{},
       do: ""

  defp data_points_xml(
         config,
         %{point_colors: point_colors, point_formats: point_formats} = series
       ) do
    # A bar point without its own invertIfNegative falls back to the schema
    # default of true, and PowerPoint paints a negative bar white whatever
    # fill the point was given. State it on every bar point, as on the series.
    invert_xml = invert_if_negative_xml(config, series)

    # Merge point_colors (shorthand) and point_formats into a unified map
    merged =
      Enum.reduce(point_colors, %{}, fn {idx, color}, acc ->
        # On a line-type series the colour fills and outlines the marker
        color_opts =
          if line_series?(config) and is_binary(color),
            do: [fill: color, line: color],
            else: [fill: color]

        Map.put(acc, idx, Keyword.merge(Map.get(acc, idx, []), color_opts))
      end)

    merged =
      Enum.reduce(point_formats, merged, fn {idx, fmt}, acc ->
        Map.update(acc, idx, fmt, fn existing -> Keyword.merge(existing, fmt) end)
      end)

    merged
    |> Enum.sort_by(fn {idx, _} -> idx end)
    |> Enum.map(fn {idx, opts} ->
      # CT_DPt order: idx, invertIfNegative, marker, bubble3D, explosion, spPr
      ~s(<c:dPt>) <>
        ~s(<c:idx val="#{idx}"/>) <>
        invert_xml <>
        point_shape_xml(config, opts) <>
        ~s(</c:dPt>)
    end)
    |> Enum.join()
  end

  # On a line, scatter or (unfilled) radar series the visible part of a point
  # is its marker, so the point's fill and line format the marker; :marker
  # sets its style and size. Elsewhere they format the bar, slice or bubble.
  defp point_shape_xml(config, opts) do
    if line_series?(config) do
      marker =
        Keyword.merge(
          Keyword.take(opts, [:fill, :line]),
          Keyword.get(opts, :marker, [])
        )

      if marker == [], do: "", else: series_marker_xml(marker)
    else
      sp_pr_xml(Keyword.take(opts, [:fill, :line]))
    end
  end

  # -- Per-point data label overrides --

  # A series' labels. Labels cascade: the plot's labels (chart-level, or a
  # combo plot's own), then the series', then each point's, each level giving
  # only what it changes. PowerPoint does not inherit between these levels, so
  # each is written in full. A map of point index to options overrides those
  # points; a list also sets the series' own labels, with point overrides
  # under :points.
  defp series_data_labels_xml(labels, _plot_labels) when labels in [nil, [], %{}], do: ""

  defp series_data_labels_xml(labels, plot_labels) do
    plot = label_opts(plot_labels)

    {series, points} =
      if is_map(labels) do
        {plot, labels}
      else
        own = label_opts(labels)
        {Keyword.merge(plot, Keyword.delete(own, :points)), Keyword.get(own, :points, %{})}
      end

    point_xml =
      points
      |> Enum.sort_by(fn {idx, _} -> idx end)
      |> Enum.map_join(fn {idx, opts} ->
        merged = Keyword.merge(series, label_opts(opts))
        ~s(<c:dLbl><c:idx val="#{idx}"/>#{dlbls_group_xml(merged)}</c:dLbl>)
      end)

    # CT_DLbls requires the group of show flags (or <c:delete>) after the
    # <c:dLbl> entries; with no labels above the series they are all off.
    ~s(<c:dLbls>#{point_xml}#{dlbls_group_xml(series)}</c:dLbls>)
  end

  # Label options as a keyword list: an atom list is what to show.
  defp label_opts(nil), do: []
  defp label_opts([]), do: []

  defp label_opts(labels) when is_list(labels) do
    if Keyword.keyword?(labels), do: labels, else: [show: labels]
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
    category_axes_xml(chart, @line_cat_ax_id, @line_val_ax_id)
  end

  defp axes_xml(chart, %{element: "c:areaChart"}) do
    category_axes_xml(chart, @area_cat_ax_id, @area_val_ax_id)
  end

  defp axes_xml(chart, %{element: "c:radarChart"}) do
    category_axes_xml(chart, @radar_cat_ax_id, @radar_val_ax_id)
  end

  # Scatter and bubble charts have two value axes: :category_axis sets the
  # horizontal (X) one and :value_axis the vertical (Y) one, as python-pptx's
  # category_axis does.
  defp axes_xml(chart, %{element: element})
       when element in ["c:scatterChart", "c:bubbleChart"] do
    xy_opts = [cross_between: "midCat"]

    value_axis_xml(chart.category_axis, @scatter_x_ax_id, @scatter_y_ax_id, "b", xy_opts) <>
      value_axis_xml(chart.value_axis, @scatter_y_ax_id, @scatter_x_ax_id, "l", xy_opts)
  end

  defp axes_xml(chart, _config) do
    category_axes_xml(chart, @cat_ax_id, @val_ax_id)
  end

  defp category_axes_xml(chart, cat_ax_id, val_ax_id) do
    category_axis_xml(
      chart.category_axis,
      cat_ax_id,
      val_ax_id,
      ChartType.cat_ax_pos(chart.chart_type)
    ) <>
      value_axis_xml(
        chart.value_axis,
        val_ax_id,
        cat_ax_id,
        ChartType.val_ax_pos(chart.chart_type),
        []
      )
  end

  # A category axis, or a date axis with `type: :date`.
  defp category_axis_xml(axis_opts, ax_id, cross_ax_id, pos) do
    axis_opts = axis_opts || []
    scaling = scaling_xml(axis_opts, false)

    case Keyword.get(axis_opts, :type) do
      :date ->
        ~s(<c:dateAx>) <>
          axis_shared_xml(axis_opts, ax_id, cross_ax_id, pos, scaling, false, :auto_zero) <>
          label_offset_xml(Keyword.get(axis_opts, :label_offset)) <>
          time_unit_xml("baseTimeUnit", Keyword.get(axis_opts, :base_time_unit)) <>
          unit_xml("majorUnit", Keyword.get(axis_opts, :major_unit)) <>
          time_unit_xml("majorTimeUnit", Keyword.get(axis_opts, :major_time_unit)) <>
          unit_xml("minorUnit", Keyword.get(axis_opts, :minor_unit)) <>
          time_unit_xml("minorTimeUnit", Keyword.get(axis_opts, :minor_time_unit)) <>
          ~s(</c:dateAx>)

      _ ->
        ~s(<c:catAx>) <>
          axis_shared_xml(axis_opts, ax_id, cross_ax_id, pos, scaling, false, :auto_zero) <>
          ~s(<c:auto val="1"/>) <>
          ~s(<c:lblAlgn val="ctr"/>) <>
          label_offset_xml(Keyword.get(axis_opts, :label_offset, 100)) <>
          ~s(<c:noMultiLvlLbl val="0"/>) <>
          ~s(</c:catAx>)
    end
  end

  # A value axis. `opts` may give :cross_between, :gridlines (the default for
  # major gridlines, true) and :crosses (the default crossing, :auto_zero).
  defp value_axis_xml(axis_opts, ax_id, cross_ax_id, pos, opts) do
    axis_opts = axis_opts || []
    gridlines = Keyword.get(opts, :gridlines, true)
    crosses = Keyword.get(opts, :crosses, :auto_zero)

    cross_between_xml =
      case Keyword.get(opts, :cross_between) do
        nil -> ""
        val -> ~s(<c:crossBetween val="#{val}"/>)
      end

    ~s(<c:valAx>) <>
      axis_shared_xml(
        axis_opts,
        ax_id,
        cross_ax_id,
        pos,
        scaling_xml(axis_opts, true),
        gridlines,
        crosses
      ) <>
      cross_between_xml <>
      unit_xml("majorUnit", Keyword.get(axis_opts, :major_unit)) <>
      unit_xml("minorUnit", Keyword.get(axis_opts, :minor_unit)) <>
      ~s(</c:valAx>)
  end

  # EG_AxShared, in schema order: axId, scaling, delete, axPos, majorGridlines,
  # minorGridlines, title, numFmt, majorTickMark, minorTickMark, tickLblPos,
  # spPr, txPr, crossAx, crosses/crossesAt.
  defp axis_shared_xml(axis_opts, ax_id, cross_ax_id, pos, scaling, gridlines, crosses) do
    delete_val = if Keyword.get(axis_opts, :visible, true), do: "0", else: "1"

    ~s(<c:axId val="#{ax_id}"/>) <>
      scaling <>
      ~s(<c:delete val="#{delete_val}"/>) <>
      ~s(<c:axPos val="#{pos}"/>) <>
      gridlines_xml("majorGridlines", Keyword.get(axis_opts, :major_gridlines, gridlines)) <>
      gridlines_xml("minorGridlines", Keyword.get(axis_opts, :minor_gridlines, false)) <>
      axis_title_xml(Keyword.get(axis_opts, :title)) <>
      val_num_fmt_xml(Keyword.get(axis_opts, :number_format)) <>
      ~s(<c:majorTickMark val="#{tick_mark_value(Keyword.get(axis_opts, :major_tick_mark, :out))}"/>) <>
      ~s(<c:minorTickMark val="#{tick_mark_value(Keyword.get(axis_opts, :minor_tick_mark, :none))}"/>) <>
      ~s(<c:tickLblPos val="#{tick_label_position_value(Keyword.get(axis_opts, :tick_label_position, :next_to))}"/>) <>
      sp_pr_xml(axis_opts) <>
      tick_label_format_xml(axis_opts) <>
      ~s(<c:crossAx val="#{cross_ax_id}"/>) <>
      crosses_xml(Keyword.get(axis_opts, :crosses, crosses))
  end

  # Category and date axes take no :min or :max.
  defp scaling_xml(axis_opts, value_axis?) do
    reverse = Keyword.get(axis_opts, :reverse, false)

    if value_axis? do
      val_scaling_xml(Keyword.get(axis_opts, :min), Keyword.get(axis_opts, :max), reverse)
    else
      orientation = if reverse, do: "maxMin", else: "minMax"
      ~s(<c:scaling><c:orientation val="#{orientation}"/></c:scaling>)
    end
  end

  defp tick_label_position_value(:next_to), do: "nextTo"
  defp tick_label_position_value(:low), do: "low"
  defp tick_label_position_value(:high), do: "high"
  defp tick_label_position_value(:none), do: "none"

  defp label_offset_xml(nil), do: ""
  defp label_offset_xml(offset), do: ~s(<c:lblOffset val="#{offset}"/>)

  defp unit_xml(_tag, nil), do: ""
  defp unit_xml(tag, value), do: ~s(<c:#{tag} val="#{value}"/>)

  defp time_unit_xml(_tag, nil), do: ""
  defp time_unit_xml(tag, unit), do: ~s(<c:#{tag} val="#{time_unit_value(unit)}"/>)

  defp time_unit_value(:days), do: "days"
  defp time_unit_value(:months), do: "months"
  defp time_unit_value(:years), do: "years"

  defp crosses_xml(:auto_zero), do: ~s(<c:crosses val="autoZero"/>)
  defp crosses_xml(:min), do: ~s(<c:crosses val="min"/>)
  defp crosses_xml(:max), do: ~s(<c:crosses val="max"/>)

  defp crosses_xml(value) when is_number(value),
    do: ~s(<c:crossesAt val="#{value}"/>)

  defp val_scaling_xml(min_val, max_val, reverse) do
    orientation = if reverse, do: "maxMin", else: "minMax"
    min_xml = if min_val, do: ~s(<c:min val="#{min_val}"/>), else: ""
    max_xml = if max_val, do: ~s(<c:max val="#{max_val}"/>), else: ""
    # CT_Scaling order: logBase, orientation, max, min
    ~s(<c:scaling><c:orientation val="#{orientation}"/>#{max_xml}#{min_xml}</c:scaling>)
  end

  defp val_num_fmt_xml(nil), do: ""

  defp val_num_fmt_xml(fmt) do
    ~s(<c:numFmt formatCode="#{Builder.escape(fmt)}" sourceLinked="0"/>)
  end

  defp axis_title_xml(nil), do: ""

  defp axis_title_xml(title), do: title_xml(title)

  defp title_sp_pr_xml(title) when is_list(title) and title != [] do
    if Keyword.keyword?(title), do: sp_pr_xml(title), else: ""
  end

  defp title_sp_pr_xml(_title), do: ""

  # The <c:tx> of a chart or axis title. A title is a string, rich text (a
  # list of paragraphs, as for a text box), or a keyword list with `:text`
  # (either of those) and font options that apply to every run, under the
  # runs' own options.
  defp title_text_xml(title) do
    paragraphs = title_paragraphs(title)

    ~s(<c:tx><c:rich><a:bodyPr/><a:lstStyle/>) <>
      Text.paragraphs_xml(paragraphs) <> ~s(</c:rich></c:tx>)
  end

  defp title_paragraphs(title) when is_binary(title), do: Text.normalize(title)

  defp title_paragraphs(title) when is_list(title) do
    {text, font} =
      if Keyword.keyword?(title) and title != [] do
        {Keyword.fetch!(title, :text), font_opts(title)}
      else
        {title, []}
      end

    text
    |> Text.normalize()
    |> Enum.map(fn para ->
      %{para | runs: Enum.map(para.runs, &title_run(&1, font))}
    end)
  end

  defp title_run(%{opts: opts} = run, font) do
    if Keyword.has_key?(opts, :hyperlink) do
      raise ArgumentError, "chart and axis titles do not support hyperlinks"
    end

    %{run | opts: Keyword.merge(font, opts)}
  end

  # Gridlines are off (false or nil), on (true), or on and formatted by a
  # keyword list with :line.
  defp gridlines_xml(_tag, off) when off in [false, nil], do: ""
  defp gridlines_xml(tag, true), do: ~s(<c:#{tag}/>)

  defp gridlines_xml(tag, opts) when is_list(opts),
    do: ~s(<c:#{tag}>#{sp_pr_xml(opts)}</c:#{tag}>)

  # <c:spPr> from the :fill and :line in opts, or "" when it has neither.
  defp sp_pr_xml(opts) do
    fill = Keyword.get(opts, :fill)
    line = Keyword.get(opts, :line)

    if is_nil(fill) and is_nil(line) do
      ""
    else
      fill_xml = if is_nil(fill), do: "", else: Drawing.fill_xml(fill)
      ~s(<c:spPr>#{fill_xml}#{Drawing.line_xml(line)}</c:spPr>)
    end
  end

  defp tick_label_format_xml(axis_opts) do
    body_attrs =
      case Keyword.get(axis_opts, :label_rotation) do
        nil -> ""
        degrees -> ~s( rot="#{round(degrees * 60_000)}")
      end

    text_props_xml(font_opts(axis_opts), body_attrs)
  end

  defp font_opts(opts), do: Keyword.take(opts, Text.font_keys())

  # <c:txPr>: the default text formatting of a chart element (or of the
  # whole chart), with `body_attrs` on its <a:bodyPr>.
  defp text_props_xml(font, body_attrs \\ "")
  defp text_props_xml([], ""), do: ""

  defp text_props_xml(font, body_attrs) do
    ~s(<c:txPr><a:bodyPr#{body_attrs}/><a:lstStyle/>) <>
      ~s(<a:p><a:pPr>#{Text.default_run_properties_xml(font)}</a:pPr>) <>
      ~s(<a:endParaRPr lang="en-US"/></a:p></c:txPr>)
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
      plot_area_layout_xml(chart.plot_area) <>
      combo_plots_xml(chart) <>
      combo_axes_xml(chart, has_secondary) <>
      sp_pr_xml(chart.plot_area) <>
      ~s(</c:plotArea>) <>
      legend_xml(chart.legend) <>
      ~s(<c:dispBlanksAs val="gap"/>) <>
      ~s(</c:chart>) <>
      chart_area_xml(chart.background) <>
      chart_text_xml(chart.text) <>
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
            combo_plot_options(chart, plot)
          )

        {xml_acc <> plot_xml, global_offset + length(selected_series)}
      end)

    plots_xml
  end

  # A plot's own options, falling back to the chart's.
  defp combo_plot_options(chart, plot) do
    %{
      gap_width: plot.gap_width || chart.gap_width,
      overlap: plot.overlap || chart.overlap,
      vary_by_categories:
        if(is_nil(plot.vary_by_categories),
          do: chart.vary_by_categories,
          else: plot.vary_by_categories
        ),
      data_labels: if(is_nil(plot.data_labels), do: chart.data_labels, else: plot.data_labels)
    }
  end

  defp combo_single_plot_xml(
         %{element: "c:barChart"} = config,
         chart_data,
         series_list,
         cat_ax_id,
         val_ax_id,
         global_indices,
         plot_opts
       ) do
    series_xml =
      series_list
      |> Enum.zip(global_indices)
      |> Enum.map(fn {series, global_idx} ->
        combo_series_xml(
          Map.put(config, :plot_labels, plot_opts.data_labels),
          chart_data,
          series,
          global_idx
        )
      end)
      |> Enum.join()

    ~s(<c:barChart>) <>
      ~s(<c:barDir val="#{config.bar_dir}"/>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      bar_vary_colors_xml(plot_opts.vary_by_categories) <>
      series_xml <>
      data_labels_xml(plot_opts.data_labels) <>
      gap_width_xml(plot_opts.gap_width) <>
      overlap_xml(config, plot_opts.overlap) <>
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
         plot_opts
       ) do
    series_xml =
      series_list
      |> Enum.zip(global_indices)
      |> Enum.map(fn {series, global_idx} ->
        combo_series_xml(
          Map.put(config, :plot_labels, plot_opts.data_labels),
          chart_data,
          series,
          global_idx
        )
      end)
      |> Enum.join()

    ~s(<c:lineChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      vary_colors_xml(plot_opts.vary_by_categories, false) <>
      series_xml <>
      data_labels_xml(plot_opts.data_labels) <>
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
         plot_opts
       ) do
    series_xml =
      series_list
      |> Enum.zip(global_indices)
      |> Enum.map(fn {series, global_idx} ->
        combo_series_xml(
          Map.put(config, :plot_labels, plot_opts.data_labels),
          chart_data,
          series,
          global_idx
        )
      end)
      |> Enum.join()

    ~s(<c:areaChart>) <>
      ~s(<c:grouping val="#{config.grouping}"/>) <>
      vary_colors_xml(plot_opts.vary_by_categories, false) <>
      series_xml <>
      data_labels_xml(plot_opts.data_labels) <>
      ~s(<c:axId val="#{cat_ax_id}"/>) <>
      ~s(<c:axId val="#{val_ax_id}"/>) <>
      ~s(</c:areaChart>)
  end

  defp combo_series_xml(config, chart_data, series, global_idx) do
    marker_xml = cat_marker_xml(config, series)
    smooth_xml = cat_smooth_xml(config)
    invert_xml = invert_if_negative_xml(config, series)
    color_xml = series_sp_pr_xml(config, series)
    dpt_xml = data_points_xml(config, series)
    series_dlbls_xml = series_data_labels_xml(series.data_labels, config[:plot_labels])

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
    # The category axis sits where the first plot's chart type puts it
    cat_pos = ChartType.cat_ax_pos(hd(chart.combo.plots).chart_type)

    cat_ax = category_axis_xml(chart.category_axis, @combo_cat_ax_id, @combo_val_ax_id, cat_pos)

    primary_val_ax =
      value_axis_xml(chart.value_axis, @combo_val_ax_id, @combo_cat_ax_id, "l", [])

    # The secondary axis draws no gridlines and crosses at the maximum by
    # default, so it sits on the right without crossing the primary.
    secondary_val_ax =
      if has_secondary do
        value_axis_xml(
          chart.secondary_value_axis,
          @combo_secondary_val_ax_id,
          @combo_cat_ax_id,
          "r",
          gridlines: false,
          crosses: :max
        )
      else
        ""
      end

    cat_ax <> primary_val_ax <> secondary_val_ax
  end

  defp combo_axis_ids(%ComboChart.PlotSpec{secondary_axis: true}) do
    {@combo_cat_ax_id, @combo_secondary_val_ax_id}
  end

  defp combo_axis_ids(%ComboChart.PlotSpec{secondary_axis: false}) do
    {@combo_cat_ax_id, @combo_val_ax_id}
  end

  # The plot area's manual layout positions its inner rectangle (the area the
  # axes enclose) unless :target says :outer (including the tick labels).
  defp plot_area_layout_xml(opts) do
    target = if Keyword.get(opts, :target, :inner) == :outer, do: "outer", else: "inner"
    manual_layout_xml(opts, target)
  end

  # The chart area: transparent with :none, a fill, or [fill: ..., line: ...].
  defp chart_area_xml(nil), do: ""
  defp chart_area_xml(:none), do: sp_pr_xml(fill: :none, line: :none)
  defp chart_area_xml(opts) when is_list(opts), do: sp_pr_xml(opts)
  defp chart_area_xml(fill), do: sp_pr_xml(fill: fill)

  # Chart-wide text formatting. Chart text is 18pt unless `:text` gives
  # another size.
  defp chart_text_xml(text) do
    text |> font_opts() |> Keyword.put_new(:font_size, 18) |> text_props_xml()
  end
end
