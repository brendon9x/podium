defmodule Podium.Drawing do
  @moduledoc false

  alias Podium.Units

  @doc """
  Generates fill XML for shape properties.

  - `nil` → `<a:noFill/>`
  - `"FF0000"` → solid fill with that RGB hex color
  - `{:gradient, stops, opts}` → gradient fill
  - `{:pattern, preset, opts}` → pattern fill
  """
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

  def fill_xml({:pattern, preset, opts}) when is_atom(preset) do
    fg = Keyword.get(opts, :foreground, "000000")
    bg = Keyword.get(opts, :background, "FFFFFF")
    prst = pattern_preset(preset)

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
  def line_xml(nil), do: ""

  def line_xml(color) when is_binary(color) do
    ~s(<a:ln><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></a:ln>)
  end

  def line_xml(opts) when is_list(opts) do
    color = Keyword.fetch!(opts, :color)
    width_attr = line_width_attr(Keyword.get(opts, :width))
    dash_xml = dash_style_xml(Keyword.get(opts, :dash_style))

    ~s(<a:ln#{width_attr}><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>#{dash_xml}</a:ln>)
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

  defp pattern_preset(:dn_diag), do: "dnDiag"
  defp pattern_preset(:up_diag), do: "upDiag"
  defp pattern_preset(:lt_horz), do: "ltHorz"
  defp pattern_preset(:lt_vert), do: "ltVert"
  defp pattern_preset(:dk_dn_diag), do: "dkDnDiag"
  defp pattern_preset(:dk_up_diag), do: "dkUpDiag"
  defp pattern_preset(:dk_horz), do: "dkHorz"
  defp pattern_preset(:dk_vert), do: "dkVert"
  defp pattern_preset(:sm_grid), do: "smGrid"
  defp pattern_preset(:lg_grid), do: "lgGrid"
  defp pattern_preset(:cross), do: "cross"
  defp pattern_preset(:diag_cross), do: "diagCross"
  defp pattern_preset(:pct_5), do: "pct5"
  defp pattern_preset(:pct_10), do: "pct10"
  defp pattern_preset(:pct_20), do: "pct20"
  defp pattern_preset(:pct_25), do: "pct25"
  defp pattern_preset(:pct_30), do: "pct30"
  defp pattern_preset(:pct_40), do: "pct40"
  defp pattern_preset(:pct_50), do: "pct50"
  defp pattern_preset(:pct_60), do: "pct60"
  defp pattern_preset(:pct_70), do: "pct70"
  defp pattern_preset(:pct_75), do: "pct75"
  defp pattern_preset(:pct_80), do: "pct80"
  defp pattern_preset(:pct_90), do: "pct90"
end
