defmodule Podium.Shape do
  @moduledoc """
  Shape structs and XML generation for text boxes, auto shapes, and freeform shapes.

  Shapes are created through `text_box/3`, `auto_shape/3`, or `freeform/3` and
  rendered to OOXML via `to_xml/3`.
  """

  alias Podium.OPC.Constants
  alias Podium.{AutoShapeType, Drawing, Freeform, Text, Units}

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
    :fill_opts,
    :preset,
    :anchor,
    :auto_size,
    :word_wrap,
    :path_data
  ]

  @type t :: %__MODULE__{
          type: :text_box | :auto_shape | :freeform,
          id: pos_integer(),
          name: String.t(),
          x: non_neg_integer(),
          y: non_neg_integer(),
          width: non_neg_integer(),
          height: non_neg_integer(),
          paragraphs: [map()] | nil,
          fill: Podium.fill() | nil,
          line: Podium.line() | nil,
          rotation: number() | nil,
          margin_left: non_neg_integer() | nil,
          margin_right: non_neg_integer() | nil,
          margin_top: non_neg_integer() | nil,
          margin_bottom: non_neg_integer() | nil,
          fill_opts: keyword() | nil,
          preset: atom() | nil,
          anchor: Podium.anchor() | nil,
          auto_size: :none | :text_to_fit_shape | :shape_to_fit_text | nil,
          word_wrap: boolean() | nil,
          path_data: map() | nil
        }

  @doc """
  Creates a text box shape.
  """
  @spec text_box(pos_integer(), Podium.rich_text(), keyword()) :: t()
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
      margin_bottom: margin_emu(Keyword.get(opts, :margin_bottom)),
      anchor: Keyword.get(opts, :anchor),
      auto_size: Keyword.get(opts, :auto_size),
      word_wrap: Keyword.get(opts, :word_wrap)
    }
  end

  @doc """
  Creates an auto shape with a preset geometry.
  """
  @spec auto_shape(pos_integer(), atom(), keyword()) :: t()
  def auto_shape(id, preset, opts) when is_atom(preset) do
    {_prst, basename} = AutoShapeType.lookup(preset)

    x = Units.to_emu(Keyword.fetch!(opts, :x))
    y = Units.to_emu(Keyword.fetch!(opts, :y))
    width = Units.to_emu(Keyword.fetch!(opts, :width))
    height = Units.to_emu(Keyword.fetch!(opts, :height))

    text = Keyword.get(opts, :text)

    paragraphs =
      if text do
        Text.normalize(text, opts)
      else
        nil
      end

    %__MODULE__{
      type: :auto_shape,
      id: id,
      name: "#{basename} #{id - 1}",
      x: x,
      y: y,
      width: width,
      height: height,
      preset: preset,
      paragraphs: paragraphs,
      fill: Keyword.get(opts, :fill),
      line: Keyword.get(opts, :line),
      rotation: Keyword.get(opts, :rotation),
      margin_left: margin_emu(Keyword.get(opts, :margin_left)),
      margin_right: margin_emu(Keyword.get(opts, :margin_right)),
      margin_top: margin_emu(Keyword.get(opts, :margin_top)),
      margin_bottom: margin_emu(Keyword.get(opts, :margin_bottom)),
      anchor: auto_shape_anchor(text, opts),
      auto_size: Keyword.get(opts, :auto_size),
      word_wrap: Keyword.get(opts, :word_wrap)
    }
  end

  @doc """
  Creates a freeform shape from a Freeform builder.
  """
  @spec freeform(pos_integer(), Podium.Freeform.t(), keyword()) :: t()
  def freeform(id, %Freeform{} = fb, opts) do
    {min_x, min_y, dx, dy} = Freeform.bounding_box(fb)
    origin_x = Units.to_emu(Keyword.get(opts, :origin_x, 0))
    origin_y = Units.to_emu(Keyword.get(opts, :origin_y, 0))

    %__MODULE__{
      type: :freeform,
      id: id,
      name: "Freeform #{id - 1}",
      x: origin_x + round(min_x * fb.x_scale),
      y: origin_y + round(min_y * fb.y_scale),
      width: round(dx * fb.x_scale),
      height: round(dy * fb.y_scale),
      path_data: %{operations: Freeform.shape_operations(fb), path_w: dx, path_h: dy},
      fill: Keyword.get(opts, :fill),
      line: Keyword.get(opts, :line),
      rotation: Keyword.get(opts, :rotation),
      paragraphs: nil
    }
  end

  @doc """
  Generates XML for a shape.
  """
  @spec to_xml(t(), String.t() | nil, map()) :: String.t()
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

  def to_xml(%__MODULE__{type: :auto_shape} = shape, _fill_rid, hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)

    prst = AutoShapeType.prst(shape.preset)
    rot_attr = rotation_attr(shape.rotation)

    # For auto shapes: nil fill means omit (let theme style apply); explicit fill is rendered
    fill_out =
      case shape.fill do
        nil -> ""
        other -> Drawing.fill_xml(other)
      end

    body_content =
      if shape.paragraphs do
        Text.paragraphs_xml(shape.paragraphs, hyperlink_rids)
      else
        "<a:p/>"
      end

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="#{shape.id}" name="#{shape.name}"/>) <>
      ~s(<p:cNvSpPr/>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm#{rot_attr}>) <>
      ~s(<a:off x="#{shape.x}" y="#{shape.y}"/>) <>
      ~s(<a:ext cx="#{shape.width}" cy="#{shape.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:prstGeom prst="#{prst}"><a:avLst/></a:prstGeom>) <>
      fill_out <>
      Drawing.line_xml(shape.line) <>
      ~s(</p:spPr>) <>
      style_xml() <>
      ~s(<p:txBody>) <>
      body_pr_xml(shape) <>
      ~s(<a:lstStyle/>) <>
      body_content <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  def to_xml(%__MODULE__{type: :freeform} = shape, _fill_rid, _hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    rot_attr = rotation_attr(shape.rotation)

    fill_out =
      case shape.fill do
        nil -> ""
        other -> Drawing.fill_xml(other)
      end

    path_data = shape.path_data
    path_w = round(path_data.path_w)
    path_h = round(path_data.path_h)

    path_elements =
      Enum.map(path_data.operations, fn
        {:move_to, x, y} ->
          ~s(<a:moveTo><a:pt x="#{round(x)}" y="#{round(y)}"/></a:moveTo>)

        {:line_to, x, y} ->
          ~s(<a:lnTo><a:pt x="#{round(x)}" y="#{round(y)}"/></a:lnTo>)

        :close ->
          ~s(<a:close/>)
      end)
      |> Enum.join()

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="#{shape.id}" name="#{shape.name}"/>) <>
      ~s(<p:cNvSpPr/>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm#{rot_attr}>) <>
      ~s(<a:off x="#{shape.x}" y="#{shape.y}"/>) <>
      ~s(<a:ext cx="#{shape.width}" cy="#{shape.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:custGeom>) <>
      ~s(<a:avLst/>) <>
      ~s(<a:gdLst/>) <>
      ~s(<a:ahLst/>) <>
      ~s(<a:cxnLst/>) <>
      ~s(<a:rect l="l" t="t" r="r" b="b"/>) <>
      ~s(<a:pathLst>) <>
      ~s(<a:path w="#{path_w}" h="#{path_h}">) <>
      path_elements <>
      ~s(</a:path>) <>
      ~s(</a:pathLst>) <>
      ~s(</a:custGeom>) <>
      fill_out <>
      Drawing.line_xml(shape.line) <>
      ~s(</p:spPr>) <>
      freeform_style_xml() <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr wrap="square" rtlCol="0"/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p/>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  defp freeform_style_xml do
    ~s(<p:style>) <>
      ~s(<a:lnRef idx="1"><a:schemeClr val="accent1"/></a:lnRef>) <>
      ~s(<a:fillRef idx="3"><a:schemeClr val="accent1"/></a:fillRef>) <>
      ~s(<a:effectRef idx="2"><a:schemeClr val="accent1"/></a:effectRef>) <>
      ~s(<a:fontRef idx="minor"><a:schemeClr val="lt1"/></a:fontRef>) <>
      ~s(</p:style>)
  end

  defp style_xml do
    ~s(<p:style>) <>
      ~s(<a:lnRef idx="2"><a:schemeClr val="accent1"><a:shade val="50000"/></a:schemeClr></a:lnRef>) <>
      ~s(<a:fillRef idx="1"><a:schemeClr val="accent1"/></a:fillRef>) <>
      ~s(<a:effectRef idx="0"><a:schemeClr val="accent1"/></a:effectRef>) <>
      ~s(<a:fontRef idx="minor"><a:schemeClr val="lt1"/></a:fontRef>) <>
      ~s(</p:style>)
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

    wrap = wrap_value(shape.word_wrap)
    anchor_attr = anchor_attr(shape.anchor)
    auto_size_child = auto_size_xml(shape.auto_size)

    if auto_size_child == "" do
      ~s(<a:bodyPr wrap="#{wrap}" rtlCol="0"#{margin_attrs}#{anchor_attr}/>)
    else
      ~s(<a:bodyPr wrap="#{wrap}" rtlCol="0"#{margin_attrs}#{anchor_attr}>#{auto_size_child}</a:bodyPr>)
    end
  end

  defp wrap_value(false), do: "none"
  defp wrap_value(_), do: "square"

  defp auto_size_xml(nil), do: ""
  defp auto_size_xml(:none), do: "<a:noAutofit/>"
  defp auto_size_xml(:text_to_fit_shape), do: "<a:normAutofit/>"
  defp auto_size_xml(:shape_to_fit_text), do: "<a:spAutoFit/>"

  defp anchor_attr(nil), do: ""
  defp anchor_attr(:top), do: ~s( anchor="t")
  defp anchor_attr(:middle), do: ~s( anchor="ctr")
  defp anchor_attr(:bottom), do: ~s( anchor="b")

  defp margin_attr(_name, nil), do: nil
  defp margin_attr(name, value), do: ~s( #{name}="#{value}")

  defp margin_emu(nil), do: nil
  defp margin_emu(value), do: Units.to_emu(value)

  defp auto_shape_anchor(nil, opts), do: Keyword.get(opts, :anchor)
  defp auto_shape_anchor(_text, opts), do: Keyword.get(opts, :anchor, :middle)

  defp rotation_attr(nil), do: ""
  defp rotation_attr(degrees), do: ~s( rot="#{round(degrees * 60_000)}")
end
