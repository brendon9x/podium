defmodule Podium.CSS do
  @moduledoc """
  Parses CSS-style strings into Podium options.

  This module provides a familiar CSS syntax for specifying element positions,
  sizes, and common properties, as an alternative to Elixir keyword opts:

      # CSS style string
      style: "left: 10%; top: 5%; width: 80%; height: 15%; text-align: center"

      # Equivalent keyword opts
      x: {10, :percent}, y: {5, :percent}, width: {80, :percent}, height: {15, :percent}, alignment: :center

  ## Supported Properties

  | CSS Property       | Maps to         | Values                                    |
  |-------------------|-----------------|-------------------------------------------|
  | `left`            | `:x`            | dimension (see units below)               |
  | `top`             | `:y`            | dimension                                 |
  | `width`           | `:width`        | dimension                                 |
  | `height`          | `:height`       | dimension                                 |
  | `text-align`      | `:alignment`    | `left`, `center`, `right`, `justify`      |
  | `vertical-align`  | `:anchor`       | `top`, `middle`, `bottom`                 |
  | `background`      | `:fill`         | hex color (`#FF0000` or `FF0000`)         |
  | `padding`         | all `:margin_*` | single dimension value for all four sides |
  | `padding-left`    | `:margin_left`  | dimension                                 |
  | `padding-right`   | `:margin_right` | dimension                                 |
  | `padding-top`     | `:margin_top`   | dimension                                 |
  | `padding-bottom`  | `:margin_bottom`| dimension                                 |

  Padding properties do not support `%` values — use `pt`, `in`, or `cm` instead.

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

  @position_properties %{
    "left" => :x,
    "top" => :y,
    "width" => :width,
    "height" => :height
  }

  @padding_properties %{
    "padding-left" => :margin_left,
    "padding-right" => :margin_right,
    "padding-top" => :margin_top,
    "padding-bottom" => :margin_bottom
  }

  @text_align_values %{
    "left" => :left,
    "center" => :center,
    "right" => :right,
    "justify" => :justify
  }

  @vertical_align_values %{
    "top" => :top,
    "middle" => :middle,
    "bottom" => :bottom
  }

  @doc """
  Parses a CSS style string into a keyword list of Podium options.

  ## Examples

      iex> Podium.CSS.parse_style("left: 10%; top: 5%; width: 80%; height: 15%")
      [x: {10, :percent}, y: {5, :percent}, width: {80, :percent}, height: {15, :percent}]

      iex> Podium.CSS.parse_style("text-align: center; vertical-align: middle")
      [alignment: :center, anchor: :middle]

      iex> Podium.CSS.parse_style("background: #FF0000")
      [fill: "FF0000"]

      iex> Podium.CSS.parse_style("padding: 12pt")
      [margin_left: {12, :pt}, margin_right: {12, :pt}, margin_top: {12, :pt}, margin_bottom: {12, :pt}]
  """
  @spec parse_style(String.t()) :: keyword()
  def parse_style(style) when is_binary(style) do
    style
    |> String.split(";")
    |> Enum.flat_map(&parse_declaration/1)
  end

  defp parse_declaration(declaration) do
    case String.split(declaration, ":", parts: 2) do
      [property, value] ->
        property = String.trim(property)
        value = String.trim(value)
        dispatch_property(property, value)

      _ ->
        []
    end
  end

  defp dispatch_property(property, value) do
    case Map.fetch(@position_properties, property) do
      {:ok, key} -> [{key, parse_value(value)}]
      :error -> dispatch_non_position(property, value)
    end
  end

  defp dispatch_non_position("text-align", value),
    do: parse_enum(value, @text_align_values, :alignment, "text-align")

  defp dispatch_non_position("vertical-align", value),
    do: parse_enum(value, @vertical_align_values, :anchor, "vertical-align")

  defp dispatch_non_position("background", value),
    do: parse_color(value)

  defp dispatch_non_position("padding", value),
    do: parse_padding_shorthand(value)

  defp dispatch_non_position(property, value) do
    case Map.fetch(@padding_properties, property) do
      {:ok, key} -> [{key, parse_padding_value(value)}]
      :error -> []
    end
  end

  defp parse_enum(value, valid_values, key, property_name) do
    case Map.fetch(valid_values, value) do
      {:ok, atom} ->
        [{key, atom}]

      :error ->
        valid = Map.keys(valid_values) |> Enum.join(", ")

        raise ArgumentError,
              "invalid #{property_name} value: #{inspect(value)}. Valid values: #{valid}"
    end
  end

  defp parse_color(value) do
    hex = String.trim_leading(value, "#")

    if Regex.match?(~r/^[0-9a-fA-F]{6}$/, hex) do
      [{:fill, String.upcase(hex)}]
    else
      raise ArgumentError,
            "invalid background color: #{inspect(value)}. Expected 6-digit hex color (e.g. #FF0000 or FF0000)"
    end
  end

  defp parse_padding_shorthand(value) do
    case String.split(value) do
      [single] ->
        dim = parse_padding_value(single)
        [margin_left: dim, margin_right: dim, margin_top: dim, margin_bottom: dim]

      _multiple ->
        raise ArgumentError,
              "multi-value padding shorthand is not supported. Use individual padding-left, padding-right, padding-top, padding-bottom properties"
    end
  end

  defp parse_padding_value(value) do
    dim = parse_value(value)

    case dim do
      {_, :percent} ->
        raise ArgumentError,
              "percent values are not supported for padding properties. Use pt, in, or cm instead"

      _ ->
        dim
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
