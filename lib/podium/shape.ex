defmodule Podium.Shape do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.{Drawing, Text, Units}

  defstruct [
    :type,
    :id,
    :name,
    :x,
    :y,
    :width,
    :height,
    :paragraphs,
    :fill,
    :line
  ]

  @doc """
  Creates a text box shape.
  """
  def text_box(id, text, opts) do
    x = Units.to_emu(Keyword.fetch!(opts, :x))
    y = Units.to_emu(Keyword.fetch!(opts, :y))
    width = Units.to_emu(Keyword.fetch!(opts, :width))
    height = Units.to_emu(Keyword.fetch!(opts, :height))

    paragraphs = Text.normalize(text, opts)

    %__MODULE__{
      type: :text_box,
      id: id,
      name: "TextBox #{id - 1}",
      x: x,
      y: y,
      width: width,
      height: height,
      paragraphs: paragraphs,
      fill: Keyword.get(opts, :fill),
      line: Keyword.get(opts, :line)
    }
  end

  @doc """
  Generates XML for a shape.
  """
  def to_xml(%__MODULE__{type: :text_box} = shape) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    body_xml = Text.paragraphs_xml(shape.paragraphs)

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
      Drawing.fill_xml(shape.fill) <>
      Drawing.line_xml(shape.line) <>
      ~s(</p:spPr>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr wrap="square" rtlCol="0"/>) <>
      ~s(<a:lstStyle/>) <>
      body_xml <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end
end
