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
    :line,
    :rotation,
    :margin_left,
    :margin_right,
    :margin_top,
    :margin_bottom,
    :fill_opts
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
      line: Keyword.get(opts, :line),
      rotation: Keyword.get(opts, :rotation),
      margin_left: margin_emu(Keyword.get(opts, :margin_left)),
      margin_right: margin_emu(Keyword.get(opts, :margin_right)),
      margin_top: margin_emu(Keyword.get(opts, :margin_top)),
      margin_bottom: margin_emu(Keyword.get(opts, :margin_bottom))
    }
  end

  @doc """
  Generates XML for a shape.
  """
  def to_xml(shape, fill_rid \\ nil, hyperlink_rids \\ %{})

  def to_xml(%__MODULE__{type: :text_box} = shape, fill_rid, hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    body_xml = Text.paragraphs_xml(shape.paragraphs, hyperlink_rids)

    rot_attr = rotation_attr(shape.rotation)

    fill_out =
      case {shape.fill, fill_rid} do
        {{:picture_fill, _idx}, rid} when is_binary(rid) ->
          Drawing.fill_xml({:picture, rid, shape.fill_opts || []})

        _ ->
          Drawing.fill_xml(shape.fill)
      end

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="#{shape.id}" name="#{shape.name}"/>) <>
      ~s(<p:cNvSpPr txBox="1"/>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm#{rot_attr}>) <>
      ~s(<a:off x="#{shape.x}" y="#{shape.y}"/>) <>
      ~s(<a:ext cx="#{shape.width}" cy="#{shape.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>) <>
      fill_out <>
      Drawing.line_xml(shape.line) <>
      ~s(</p:spPr>) <>
      ~s(<p:txBody>) <>
      body_pr_xml(shape) <>
      ~s(<a:lstStyle/>) <>
      body_xml <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  defp body_pr_xml(shape) do
    margin_attrs =
      [
        margin_attr("lIns", shape.margin_left),
        margin_attr("rIns", shape.margin_right),
        margin_attr("tIns", shape.margin_top),
        margin_attr("bIns", shape.margin_bottom)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join()

    ~s(<a:bodyPr wrap="square" rtlCol="0"#{margin_attrs}/>)
  end

  defp margin_attr(_name, nil), do: nil
  defp margin_attr(name, value), do: ~s( #{name}="#{value}")

  defp margin_emu(nil), do: nil
  defp margin_emu(value), do: Units.to_emu(value)

  defp rotation_attr(nil), do: ""
  defp rotation_attr(degrees), do: ~s( rot="#{round(degrees * 60_000)}")
end
