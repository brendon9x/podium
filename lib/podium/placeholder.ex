defmodule Podium.Placeholder do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.Text

  defstruct [
    :type,
    :idx,
    :paragraphs
  ]

  @layout_placeholders %{
    title_slide: %{
      title: %{type: "ctrTitle", idx: nil},
      subtitle: %{type: "subTitle", idx: 1}
    },
    title_content: %{
      title: %{type: "title", idx: nil},
      body: %{type: "body", idx: 1}
    },
    blank: %{}
  }

  @doc """
  Returns the known placeholder definitions for a layout.
  """
  def placeholders_for(layout) when is_atom(layout) do
    Map.get(@layout_placeholders, layout, %{})
  end

  @doc """
  Creates a placeholder shape for the given placeholder name and text.
  """
  def new(layout, name, text) when is_atom(layout) and is_atom(name) do
    defs = placeholders_for(layout)

    case Map.get(defs, name) do
      nil ->
        raise ArgumentError,
              "unknown placeholder #{inspect(name)} for layout #{inspect(layout)}"

      %{type: type, idx: idx} ->
        paragraphs = Text.normalize(text)
        %__MODULE__{type: type, idx: idx, paragraphs: paragraphs}
    end
  end

  @doc """
  Generates the <p:sp> XML for a placeholder shape.
  Placeholders inherit position from the slide layout, so no explicit <p:spPr> transform.
  """
  def to_xml(%__MODULE__{} = ph) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    idx_attr = if ph.idx, do: ~s( idx="#{ph.idx}"), else: ""
    body_xml = Text.paragraphs_xml(ph.paragraphs)

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph type="#{ph.type}"#{idx_attr}/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      body_xml <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end
end
