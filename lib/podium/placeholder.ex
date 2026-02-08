defmodule Podium.Placeholder do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.Text

  defstruct [
    :type,
    :idx,
    :kind,
    :paragraphs,
    :image_rid,
    :field_text
  ]

  @layout_placeholders %{
    title_slide: %{
      title: %{type: "ctrTitle", idx: nil},
      subtitle: %{type: "subTitle", idx: 1}
    },
    title_content: %{
      title: %{type: "title", idx: nil},
      content: %{type: nil, idx: 1}
    },
    section_header: %{
      title: %{type: "title", idx: nil},
      body: %{type: "body", idx: 1}
    },
    two_content: %{
      title: %{type: "title", idx: nil},
      left_content: %{type: nil, idx: 1},
      right_content: %{type: nil, idx: 2}
    },
    comparison: %{
      title: %{type: "title", idx: nil},
      left_heading: %{type: "body", idx: 1},
      left_content: %{type: nil, idx: 2},
      right_heading: %{type: "body", idx: 3},
      right_content: %{type: nil, idx: 4}
    },
    title_only: %{
      title: %{type: "title", idx: nil}
    },
    blank: %{},
    content_caption: %{
      title: %{type: "title", idx: nil},
      content: %{type: nil, idx: 1},
      caption: %{type: "body", idx: 2}
    },
    picture_caption: %{
      title: %{type: "title", idx: nil},
      picture: %{type: "pic", idx: 1},
      caption: %{type: "body", idx: 2}
    },
    title_vertical_text: %{
      title: %{type: "title", idx: nil},
      body: %{type: "body", idx: 1}
    },
    vertical_title_text: %{
      title: %{type: "title", idx: nil},
      body: %{type: "body", idx: 1}
    }
  }

  @doc """
  Returns the known placeholder definitions for a layout.
  """
  def placeholders_for(layout) when is_atom(layout) do
    Map.get(@layout_placeholders, layout, %{})
  end

  @doc """
  Creates a text placeholder shape for the given placeholder name and text.
  """
  def new(layout, name, text) when is_atom(layout) and is_atom(name) do
    defs = placeholders_for(layout)

    case Map.get(defs, name) do
      nil ->
        raise ArgumentError,
              "unknown placeholder #{inspect(name)} for layout #{inspect(layout)}"

      %{type: "pic"} ->
        raise ArgumentError,
              "placeholder #{inspect(name)} is a picture placeholder; " <>
                "use Podium.set_picture_placeholder/4 instead"

      %{type: type, idx: idx} ->
        paragraphs = Text.normalize(text)
        %__MODULE__{type: type, idx: idx, kind: :text, paragraphs: paragraphs}
    end
  end

  @doc """
  Creates a picture placeholder struct (kind: :picture).
  """
  def new_picture(layout, name) when is_atom(layout) and is_atom(name) do
    defs = placeholders_for(layout)

    case Map.get(defs, name) do
      nil ->
        raise ArgumentError,
              "unknown placeholder #{inspect(name)} for layout #{inspect(layout)}"

      %{type: "pic", idx: idx} ->
        %__MODULE__{type: "pic", idx: idx, kind: :picture}

      _ ->
        raise ArgumentError,
              "placeholder #{inspect(name)} is not a picture placeholder; " <>
                "use Podium.set_placeholder/3 for text placeholders"
    end
  end

  @doc """
  Creates a footer placeholder.
  """
  def new_footer(text) do
    %__MODULE__{type: "ftr", idx: 11, kind: :footer, field_text: text}
  end

  @doc """
  Creates a date placeholder.
  """
  def new_date(text) do
    %__MODULE__{type: "dt", idx: 10, kind: :date, field_text: text}
  end

  @doc """
  Creates a slide number placeholder.
  """
  def new_slide_number do
    %__MODULE__{type: "sldNum", idx: 12, kind: :slide_number}
  end

  @doc """
  Generates the XML for a placeholder shape.
  Dispatches based on the `:kind` field.
  """
  def to_xml(ph, hyperlink_rids \\ %{})

  def to_xml(%__MODULE__{kind: :text} = ph, hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    type_attr = if ph.type, do: ~s( type="#{ph.type}"), else: ""
    idx_attr = if ph.idx, do: ~s( idx="#{ph.idx}"), else: ""
    body_xml = Text.paragraphs_xml(ph.paragraphs, hyperlink_rids)

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph#{type_attr}#{idx_attr}/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      body_xml <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  def to_xml(%__MODULE__{kind: :picture} = ph, _hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)

    idx_attr = if ph.idx, do: ~s( idx="#{ph.idx}"), else: ""

    ~s(<p:pic xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvPicPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvPicPr><a:picLocks noGrp="1"/></p:cNvPicPr>) <>
      ~s(<p:nvPr><p:ph type="pic"#{idx_attr}/></p:nvPr>) <>
      ~s(</p:nvPicPr>) <>
      ~s(<p:blipFill>) <>
      ~s(<a:blip r:embed="#{ph.image_rid}"/>) <>
      ~s(<a:stretch><a:fillRect/></a:stretch>) <>
      ~s(</p:blipFill>) <>
      ~s(<p:spPr/>) <>
      ~s(</p:pic>)
  end

  def to_xml(%__MODULE__{kind: :footer} = ph, _hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph type="ftr" idx="11"/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escape(ph.field_text)}</a:t></a:r></a:p>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  def to_xml(%__MODULE__{kind: :date} = ph, _hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph type="dt" idx="10"/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escape(ph.field_text)}</a:t></a:r></a:p>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  def to_xml(%__MODULE__{kind: :slide_number}, _hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    fld_id = generate_guid()

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph type="sldNum" idx="12"/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p><a:fld id="#{fld_id}" type="slidenum"><a:rPr lang="en-US" smtClean="0"/><a:t>&lt;#&gt;</a:t></a:fld></a:p>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  # Backward compat: placeholders created without :kind default to :text behavior
  def to_xml(%__MODULE__{kind: nil} = ph, hyperlink_rids) do
    to_xml(%{ph | kind: :text}, hyperlink_rids)
  end

  defp escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp generate_guid do
    <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)

    :io_lib.format("{~8.16.0B-~4.16.0B-~4.16.0B-~4.16.0B-~12.16.0B}", [a, b, c, d, e])
    |> IO.iodata_to_binary()
    |> String.upcase()
  end
end
