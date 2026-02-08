defmodule Podium.Chart.ChartType do
  @moduledoc false

  @doc """
  Returns the XML configuration for a chart type.
  """
  def config(:column_clustered) do
    %{
      element: "c:barChart",
      bar_dir: "col",
      grouping: "clustered",
      overlap: nil,
      has_axes: true
    }
  end

  def config(:column_stacked) do
    %{
      element: "c:barChart",
      bar_dir: "col",
      grouping: "stacked",
      overlap: "100",
      has_axes: true
    }
  end

  def config(:bar_clustered) do
    %{
      element: "c:barChart",
      bar_dir: "bar",
      grouping: "clustered",
      overlap: nil,
      has_axes: true
    }
  end

  def config(:bar_stacked) do
    %{
      element: "c:barChart",
      bar_dir: "bar",
      grouping: "stacked",
      overlap: "100",
      has_axes: true
    }
  end

  def config(:line) do
    %{
      element: "c:lineChart",
      grouping: "standard",
      has_axes: true,
      show_marker: false
    }
  end

  def config(:line_markers) do
    %{
      element: "c:lineChart",
      grouping: "standard",
      has_axes: true,
      show_marker: true
    }
  end

  def config(:column_stacked_100) do
    %{
      element: "c:barChart",
      bar_dir: "col",
      grouping: "percentStacked",
      overlap: "100",
      has_axes: true
    }
  end

  def config(:bar_stacked_100) do
    %{
      element: "c:barChart",
      bar_dir: "bar",
      grouping: "percentStacked",
      overlap: "100",
      has_axes: true
    }
  end

  def config(:line_stacked) do
    %{
      element: "c:lineChart",
      grouping: "stacked",
      has_axes: true,
      show_marker: false
    }
  end

  def config(:line_markers_stacked) do
    %{
      element: "c:lineChart",
      grouping: "stacked",
      has_axes: true,
      show_marker: true
    }
  end

  def config(:line_stacked_100) do
    %{
      element: "c:lineChart",
      grouping: "percentStacked",
      has_axes: true,
      show_marker: false
    }
  end

  def config(:line_markers_stacked_100) do
    %{
      element: "c:lineChart",
      grouping: "percentStacked",
      has_axes: true,
      show_marker: true
    }
  end

  def config(:pie) do
    %{
      element: "c:pieChart",
      has_axes: false
    }
  end

  def config(:pie_exploded) do
    %{
      element: "c:pieChart",
      has_axes: false,
      explosion: 25
    }
  end

  def config(:area) do
    %{
      element: "c:areaChart",
      grouping: "standard",
      has_axes: true
    }
  end

  def config(:area_stacked) do
    %{
      element: "c:areaChart",
      grouping: "stacked",
      has_axes: true
    }
  end

  def config(:area_stacked_100) do
    %{
      element: "c:areaChart",
      grouping: "percentStacked",
      has_axes: true
    }
  end

  def config(:doughnut) do
    %{
      element: "c:doughnutChart",
      has_axes: false,
      hole_size: 50
    }
  end

  def config(:doughnut_exploded) do
    %{
      element: "c:doughnutChart",
      has_axes: false,
      hole_size: 50,
      explosion: 25
    }
  end

  def config(:radar) do
    %{
      element: "c:radarChart",
      has_axes: true,
      radar_style: "marker",
      hide_marker: true
    }
  end

  def config(:radar_filled) do
    %{
      element: "c:radarChart",
      has_axes: true,
      radar_style: "filled",
      hide_marker: false
    }
  end

  def config(:radar_markers) do
    %{
      element: "c:radarChart",
      has_axes: true,
      radar_style: "marker",
      hide_marker: false
    }
  end

  def config(:scatter) do
    %{
      element: "c:scatterChart",
      scatter_style: "lineMarker",
      has_axes: true,
      no_line: true,
      hide_marker: false
    }
  end

  def config(:scatter_lines) do
    %{
      element: "c:scatterChart",
      scatter_style: "lineMarker",
      has_axes: true,
      no_line: false,
      hide_marker: false
    }
  end

  def config(:scatter_lines_no_markers) do
    %{
      element: "c:scatterChart",
      scatter_style: "lineMarker",
      has_axes: true,
      no_line: false,
      hide_marker: true
    }
  end

  def config(:scatter_smooth) do
    %{
      element: "c:scatterChart",
      scatter_style: "smoothMarker",
      has_axes: true,
      no_line: false,
      hide_marker: false
    }
  end

  def config(:scatter_smooth_no_markers) do
    %{
      element: "c:scatterChart",
      scatter_style: "smoothMarker",
      has_axes: true,
      no_line: false,
      hide_marker: true
    }
  end

  def config(:bubble) do
    %{
      element: "c:bubbleChart",
      has_axes: true,
      bubble_3d: false
    }
  end

  def config(:bubble_3d) do
    %{
      element: "c:bubbleChart",
      has_axes: true,
      bubble_3d: true
    }
  end

  @doc """
  Returns axis positions based on chart type.
  """
  def cat_ax_pos(:bar_clustered), do: "l"
  def cat_ax_pos(:bar_stacked), do: "l"
  def cat_ax_pos(:bar_stacked_100), do: "l"
  def cat_ax_pos(_), do: "b"

  def val_ax_pos(:bar_clustered), do: "b"
  def val_ax_pos(:bar_stacked), do: "b"
  def val_ax_pos(:bar_stacked_100), do: "b"
  def val_ax_pos(_), do: "l"
end
