defmodule Podium.Shape do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.Units

  defstruct [
    :id,
    :name,
    :x,
    :y,
    :width,
    :height,
    :text,
    :font_size,
    to_xml: nil
  ]

  @doc """
  Creates a text box shape.
  """
  def text_box(id, text, opts) do
    x = Units.to_emu(Keyword.fetch!(opts, :x))
    y = Units.to_emu(Keyword.fetch!(opts, :y))
    width = Units.to_emu(Keyword.fetch!(opts, :width))
    height = Units.to_emu(Keyword.fetch!(opts, :height))
    font_size = Keyword.get(opts, :font_size)

    %__MODULE__{
      id: id,
      name: "TextBox #{id - 1}",
      x: x,
      y: y,
      width: width,
      height: height,
      text: text,
      font_size: font_size,
      to_xml: &text_box_xml/1
    }
  end

  defp text_box_xml(%__MODULE__{} = shape) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    escaped_text = Podium.XML.Builder.escape(shape.text)

    run_props =
      if shape.font_size do
        # Font size in OOXML is in hundredths of a point
        sz = shape.font_size * 100
        ~s(<a:rPr lang="en-US" sz="#{sz}" dirty="0"/>)
      else
        ~s(<a:rPr lang="en-US" dirty="0"/>)
      end

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="#{shape.id}" name="#{shape.name}"/>) <>
      ~s(<p:cNvSpPr txBox="1"/>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm>) <>
      ~s(<a:off x="#{shape.x}" y="#{shape.y}"/>) <>
      ~s(<a:ext cx="#{shape.width}" cy="#{shape.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>) <>
      ~s(<a:noFill/>) <>
      ~s(</p:spPr>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr wrap="square" rtlCol="0"/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p><a:r>#{run_props}<a:t>#{escaped_text}</a:t></a:r></a:p>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end
end
