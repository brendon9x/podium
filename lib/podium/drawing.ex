defmodule Podium.Drawing do
  @moduledoc """
  DrawingML fill and line XML fragment generation.

  Provides `fill_xml/1` and `line_xml/1` to render fill and line properties
  as OOXML fragments used inside shape, chart, and table elements.
  """

  alias Podium.{Pattern, Units}

  @doc """
  Generates fill XML for shape properties.

  - `nil` → `<a:noFill/>`
  - `"FF0000"` → solid fill with that RGB hex color
  - `{:gradient, stops, opts}` → gradient fill
  - `{:pattern, preset, opts}` → pattern fill
  """
  @spec fill_xml(
          Podium.fill()
          | {:picture, String.t(), keyword()}
          | {:picture_fill, non_neg_integer()}
        ) :: String.t()
  def fill_xml(nil), do: "<a:noFill/>"

  def fill_xml(color) when is_binary(color),
    do: ~s(<a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>)

  def fill_xml({:gradient, stops, opts}) when is_list(stops) do
    angle = Keyword.get(opts, :angle, 5_400_000)

    gs_list =
      Enum.map(stops, fn {pos, color} ->
        ~s(<a:gs pos="#{pos}"><a:srgbClr val="#{color}"/></a:gs>)
      end)
      |> Enum.join()

    ~s(<a:gradFill rotWithShape="1">) <>
      ~s(<a:gsLst>#{gs_list}</a:gsLst>) <>
      ~s(<a:lin ang="#{angle}" scaled="0"/>) <>
      ~s(</a:gradFill>)
  end

  # Placeholder for picture fill — should be resolved to {:picture, rid, opts} in Shape.to_xml
  def fill_xml({:picture_fill, _index}), do: "<a:noFill/>"

  def fill_xml({:picture, rid, opts}) when is_binary(rid) do
    mode = Keyword.get(opts, :mode, :stretch)

    mode_xml =
      case mode do
        :stretch -> ~s(<a:stretch><a:fillRect/></a:stretch>)
        :tile -> ~s(<a:tile tx="0" ty="0" sx="100000" sy="100000"/>)
      end

    ~s(<a:blipFill rotWithShape="1">) <>
      ~s(<a:blip r:embed="#{rid}"/>) <>
      mode_xml <>
      ~s(</a:blipFill>)
  end

  def fill_xml({:pattern, preset, opts}) when is_atom(preset) do
    fg = Keyword.get(opts, :foreground, "000000")
    bg = Keyword.get(opts, :background, "FFFFFF")
    prst = Pattern.preset(preset)

    ~s(<a:pattFill prst="#{prst}">) <>
      ~s(<a:fgClr><a:srgbClr val="#{fg}"/></a:fgClr>) <>
      ~s(<a:bgClr><a:srgbClr val="#{bg}"/></a:bgClr>) <>
      ~s(</a:pattFill>)
  end

  @doc """
  Generates line XML for shape properties.

  - `nil` → `""`
  - `"000000"` → line with default width
  - `[color: "000000", width: {2, :pt}, dash_style: :dash]` → line with width and dash style
  """
  @spec line_xml(Podium.line()) :: String.t()
  def line_xml(nil), do: ""

  def line_xml(color) when is_binary(color) do
    ~s(<a:ln><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></a:ln>)
  end

  def line_xml(opts) when is_list(opts) do
    fill = Keyword.get(opts, :fill)
    color = Keyword.get(opts, :color)
    width_attr = line_width_attr(Keyword.get(opts, :width))
    dash_xml = dash_style_xml(Keyword.get(opts, :dash_style))

    fill_content =
      cond do
        fill -> fill_xml(fill)
        color -> fill_xml(color)
      end

    ~s(<a:ln#{width_attr}>#{fill_content}#{dash_xml}</a:ln>)
  end

  defp line_width_attr(nil), do: ""
  defp line_width_attr(width), do: ~s( w="#{Units.to_emu(width)}")

  defp dash_style_xml(nil), do: ""
  defp dash_style_xml(:solid), do: ""
  defp dash_style_xml(style), do: ~s(<a:prstDash val="#{dash_value(style)}"/>)

  defp dash_value(:dash), do: "dash"
  defp dash_value(:dot), do: "dot"
  defp dash_value(:dash_dot), do: "dashDot"
  defp dash_value(:long_dash), do: "lgDash"
  defp dash_value(:long_dash_dot), do: "lgDashDot"
  defp dash_value(:long_dash_dot_dot), do: "lgDashDotDot"
  defp dash_value(:sys_dot), do: "sysDot"
  defp dash_value(:sys_dash), do: "sysDash"
  defp dash_value(:sys_dash_dot), do: "sysDashDot"
  defp dash_value(:sys_dash_dot_dot), do: "sysDashDotDot"
end
