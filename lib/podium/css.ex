defmodule Podium.CSS do
  @moduledoc """
  Parses CSS-style position strings into Podium dimension options.

  This module provides a familiar CSS syntax for specifying element positions
  and sizes, as an alternative to `{value, :unit}` tuples:

      # CSS style string
      style: "left: 10%; top: 5%; width: 80%; height: 15%"

      # Equivalent tuple opts
      x: {10, :percent}, y: {5, :percent}, width: {80, :percent}, height: {15, :percent}

  ## Supported Properties

  | CSS Property | Maps to |
  |-------------|---------|
  | `left`      | `:x`    |
  | `top`       | `:y`    |
  | `width`     | `:width`|
  | `height`    | `:height`|

  ## Supported Units

  | CSS Value    | Maps to             |
  |-------------|---------------------|
  | `10%`       | `{10, :percent}`    |
  | `2in`       | `{2, :inches}`      |
  | `5cm`       | `{5, :cm}`          |
  | `72pt`      | `{72, :pt}`         |
  | `914400`    | `914400` (raw EMU)  |

  Unrecognised properties are silently ignored.
  """

  @property_map %{
    "left" => :x,
    "top" => :y,
    "width" => :width,
    "height" => :height
  }

  @doc """
  Parses a CSS position style string into a keyword list of Podium dimension options.

  ## Examples

      iex> Podium.CSS.parse_position_style("left: 10%; top: 5%; width: 80%; height: 15%")
      [x: {10, :percent}, y: {5, :percent}, width: {80, :percent}, height: {15, :percent}]

      iex> Podium.CSS.parse_position_style("left: 2in; top: 1in")
      [x: {2, :inches}, y: {1, :inches}]

      iex> Podium.CSS.parse_position_style("left: 914400")
      [x: 914400]
  """
  @spec parse_position_style(String.t()) :: keyword()
  def parse_position_style(style) when is_binary(style) do
    style
    |> String.split(";")
    |> Enum.flat_map(&parse_declaration/1)
  end

  defp parse_declaration(declaration) do
    case String.split(declaration, ":", parts: 2) do
      [property, value] ->
        property = String.trim(property)
        value = String.trim(value)

        case Map.fetch(@property_map, property) do
          {:ok, key} -> [{key, parse_value(value)}]
          :error -> []
        end

      _ ->
        []
    end
  end

  defp parse_value(value) do
    cond do
      String.ends_with?(value, "%") ->
        {parse_number!(strip_suffix(value, "%"), value), :percent}

      String.ends_with?(value, "in") ->
        {parse_number!(strip_suffix(value, "in"), value), :inches}

      String.ends_with?(value, "cm") ->
        {parse_number!(strip_suffix(value, "cm"), value), :cm}

      String.ends_with?(value, "pt") ->
        {parse_number!(strip_suffix(value, "pt"), value), :pt}

      true ->
        parse_emu!(value)
    end
  end

  defp strip_suffix(value, suffix) do
    binary_part(value, 0, byte_size(value) - byte_size(suffix))
  end

  defp parse_number!(str, original) do
    case Float.parse(str) do
      {float, ""} ->
        truncated = trunc(float)
        if float == truncated, do: truncated, else: float

      _ ->
        raise ArgumentError, "invalid CSS value: #{inspect(original)}"
    end
  end

  defp parse_emu!(str) do
    case Integer.parse(str) do
      {int, ""} ->
        int

      _ ->
        raise ArgumentError, "invalid CSS value: #{inspect(str)}"
    end
  end
end
