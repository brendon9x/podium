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

  def config(:pie) do
    %{
      element: "c:pieChart",
      has_axes: false
    }
  end

  @doc """
  Returns axis positions based on chart type.
  """
  def cat_ax_pos(:bar_clustered), do: "l"
  def cat_ax_pos(:bar_stacked), do: "l"
  def cat_ax_pos(_), do: "b"

  def val_ax_pos(:bar_clustered), do: "b"
  def val_ax_pos(:bar_stacked), do: "b"
  def val_ax_pos(_), do: "l"
end
