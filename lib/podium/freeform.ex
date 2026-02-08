defmodule Podium.Freeform do
  @moduledoc false

  alias Podium.Units

  defstruct [:start_x, :start_y, :x_scale, :y_scale, operations: []]

  @doc """
  Creates a new freeform builder starting at (start_x, start_y).

  Coordinates can be `{value, unit}` tuples (converted to EMU) or raw integers.
  When raw integers are used with `scale: N`, coordinates are multiplied by N
  to get EMU values.

  ## Options
    * `:scale` - scale factor for raw integer coords (default 1.0, meaning EMU)
    * `:x_scale` / `:y_scale` - per-axis scale factors (override `:scale`)
  """
  def new(start_x, start_y, opts \\ []) do
    default_scale = Keyword.get(opts, :scale, 1.0)
    x_scale = Keyword.get(opts, :x_scale, default_scale)
    y_scale = Keyword.get(opts, :y_scale, default_scale)

    %__MODULE__{
      start_x: resolve_coord(start_x),
      start_y: resolve_coord(start_y),
      x_scale: x_scale / 1,
      y_scale: y_scale / 1,
      operations: []
    }
  end

  @doc """
  Adds a line segment to (x, y).
  """
  def line_to(%__MODULE__{} = fb, x, y) do
    %{fb | operations: fb.operations ++ [{:line_to, resolve_coord(x), resolve_coord(y)}]}
  end

  @doc """
  Starts a new contour at (x, y) without drawing a line.
  """
  def move_to(%__MODULE__{} = fb, x, y) do
    %{fb | operations: fb.operations ++ [{:move_to, resolve_coord(x), resolve_coord(y)}]}
  end

  @doc """
  Closes the current contour.
  """
  def close(%__MODULE__{} = fb) do
    %{fb | operations: fb.operations ++ [:close]}
  end

  @doc """
  Adds multiple line segments from a list of `{x, y}` vertices.

  ## Options
    * `:close` - if `true`, closes the contour after the last segment
  """
  def add_line_segments(%__MODULE__{} = fb, vertices, opts \\ []) do
    fb =
      Enum.reduce(vertices, fb, fn {x, y}, acc ->
        line_to(acc, x, y)
      end)

    if Keyword.get(opts, :close, false) do
      close(fb)
    else
      fb
    end
  end

  @doc """
  Computes the bounding box in local coordinates (before scale).
  Returns `{min_x, min_y, dx, dy}`.
  """
  def bounding_box(%__MODULE__{} = fb) do
    all_points = [{fb.start_x, fb.start_y} | extract_points(fb.operations)]

    {xs, ys} = Enum.unzip(all_points)
    min_x = Enum.min(xs)
    min_y = Enum.min(ys)
    max_x = Enum.max(xs)
    max_y = Enum.max(ys)

    {min_x, min_y, max_x - min_x, max_y - min_y}
  end

  @doc """
  Returns operations with coordinates translated so the bounding box origin is (0, 0).
  Includes the initial move_to from the start point.
  """
  def shape_operations(%__MODULE__{} = fb) do
    {min_x, min_y, _dx, _dy} = bounding_box(fb)

    initial = {:move_to, fb.start_x - min_x, fb.start_y - min_y}

    translated =
      Enum.map(fb.operations, fn
        {:line_to, x, y} -> {:line_to, x - min_x, y - min_y}
        {:move_to, x, y} -> {:move_to, x - min_x, y - min_y}
        :close -> :close
      end)

    [initial | translated]
  end

  defp extract_points(operations) do
    Enum.flat_map(operations, fn
      {:line_to, x, y} -> [{x, y}]
      {:move_to, x, y} -> [{x, y}]
      :close -> []
    end)
  end

  defp resolve_coord({_value, _unit} = tuple), do: Units.to_emu(tuple)
  defp resolve_coord(n) when is_number(n), do: n
end
