defmodule Podium.Chart.ComboChart do
  @moduledoc """
  Multi-type combo chart combining different chart types in one plot area.

  A combo chart splits the series from a single `ChartData` struct across
  multiple plot specs, each with its own chart type and optional secondary axis.
  """

  alias Podium.Chart.ChartType

  defmodule PlotSpec do
    @moduledoc "Specification for a single plot within a combo chart."
    defstruct [:chart_type, :series_indices, secondary_axis: false]

    @type t :: %__MODULE__{
            chart_type: atom(),
            series_indices: [non_neg_integer()],
            secondary_axis: boolean()
          }
  end

  defstruct [:chart_data, :plots]

  @type t :: %__MODULE__{
          chart_data: Podium.Chart.ChartData.t(),
          plots: [PlotSpec.t()]
        }

  @allowed_types [
    :column_clustered,
    :column_stacked,
    :column_stacked_100,
    :bar_clustered,
    :bar_stacked,
    :bar_stacked_100,
    :line,
    :line_markers,
    :line_stacked,
    :line_markers_stacked,
    :line_stacked_100,
    :line_markers_stacked_100,
    :area,
    :area_stacked,
    :area_stacked_100
  ]

  @bar_types [:bar_clustered, :bar_stacked, :bar_stacked_100]
  @column_types [:column_clustered, :column_stacked, :column_stacked_100]

  @doc """
  Creates a new combo chart from chart data and plot specifications.

  Each plot spec is a `{chart_type, opts}` tuple where opts must include
  `:series` (list of zero-based series indices). Validates that at least
  2 plots exist, series indices don't overlap, and bar/column types aren't mixed.
  """
  @spec new(Podium.Chart.ChartData.t(), [{atom(), keyword()}]) :: t()
  def new(chart_data, plot_specs) do
    plots = Enum.map(plot_specs, &parse_plot_spec/1)
    validate!(chart_data, plots)
    %__MODULE__{chart_data: chart_data, plots: plots}
  end

  defp parse_plot_spec({chart_type, opts}) do
    %PlotSpec{
      chart_type: chart_type,
      series_indices: Keyword.fetch!(opts, :series),
      secondary_axis: Keyword.get(opts, :secondary_axis, false)
    }
  end

  defp validate!(chart_data, plots) do
    if length(plots) < 2 do
      raise ArgumentError, "combo charts require at least 2 plots"
    end

    series_count = length(chart_data.series)

    Enum.each(plots, fn plot ->
      unless plot.chart_type in @allowed_types do
        raise ArgumentError,
              "unsupported chart type #{inspect(plot.chart_type)} in combo chart; " <>
                "allowed: column, bar, line, area variants"
      end

      Enum.each(plot.series_indices, fn idx ->
        if idx < 0 or idx >= series_count do
          raise ArgumentError,
                "series index #{idx} out of range (0..#{series_count - 1})"
        end
      end)
    end)

    # Check no overlapping series
    all_indices = Enum.flat_map(plots, & &1.series_indices)

    if length(all_indices) != length(Enum.uniq(all_indices)) do
      raise ArgumentError, "series indices must not overlap between plots"
    end

    # Check no mixed bar direction
    types = Enum.map(plots, & &1.chart_type)
    has_bar = Enum.any?(types, &(&1 in @bar_types))
    has_col = Enum.any?(types, &(&1 in @column_types))

    if has_bar and has_col do
      raise ArgumentError, "cannot mix horizontal bar and vertical column in same combo chart"
    end

    # Validate chart type configs exist
    Enum.each(plots, fn plot ->
      ChartType.config(plot.chart_type)
    end)
  end
end
