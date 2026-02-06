defmodule Podium.Drawing do
  @moduledoc false

  alias Podium.Units

  @doc """
  Generates fill XML for shape properties.

  - `nil` → `<a:noFill/>`
  - `"FF0000"` → solid fill with that RGB hex color
  """
  def fill_xml(nil), do: "<a:noFill/>"

  def fill_xml(color) when is_binary(color),
    do: ~s(<a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>)

  @doc """
  Generates line XML for shape properties.

  - `nil` → `""`
  - `"000000"` → line with default width
  - `[color: "000000", width: {2, :pt}]` → line with specific width
  """
  def line_xml(nil), do: ""

  def line_xml(color) when is_binary(color) do
    ~s(<a:ln><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></a:ln>)
  end

  def line_xml(opts) when is_list(opts) do
    color = Keyword.fetch!(opts, :color)
    width_attr = line_width_attr(Keyword.get(opts, :width))

    ~s(<a:ln#{width_attr}><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></a:ln>)
  end

  defp line_width_attr(nil), do: ""
  defp line_width_attr(width), do: ~s( w="#{Units.to_emu(width)}")
end
