defmodule Podium.Placeholder do
  @moduledoc """
  Layout placeholder management for slide content.

  Each slide layout defines named placeholder positions (title, subtitle, content,
  etc.) that can be filled with text or pictures. This module handles creating
  placeholder structs and rendering their XML.

  Placeholders can be addressed two ways. The bundled template's layouts have
  names (`:title`, `:content`, ...) listed in `placeholders_for/1`. Any
  template's layouts can be addressed by the `{type, idx}` pair that
  `Podium.Template.inspect/1` reports for each placeholder.
  """

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

  @type t :: %__MODULE__{
          type: String.t() | nil,
          idx: non_neg_integer() | nil,
          kind: :text | :picture | :footer | :date | :slide_number | nil,
          paragraphs: [map()] | nil,
          image_rid: String.t() | nil,
          field_text: String.t() | nil
        }

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
  @spec placeholders_for(atom()) :: %{atom() => map()}
  def placeholders_for(layout) when is_atom(layout) do
    Map.get(@layout_placeholders, layout, %{})
  end

  @doc """
  Normalises a placeholder reference to `{type, idx}` with the OOXML attribute
  defaults filled in: a missing type is `"obj"` and a missing idx is `0`.

  Accepts a `{type, idx}` tuple, a `%Podium.Placeholder{}`, or any map with
  `:type` and `:idx` keys, such as a definition from `placeholders_for/1`.
  """
  @spec normalize_ref(Podium.Template.ref()) :: {String.t(), non_neg_integer()}
  def normalize_ref({type, idx}), do: {normalize_type(type), normalize_idx(idx)}
  def normalize_ref(%{type: type, idx: idx}), do: {normalize_type(type), normalize_idx(idx)}

  defp normalize_type(nil), do: "obj"
  defp normalize_type(type) when is_binary(type), do: type

  defp normalize_idx(nil), do: 0
  defp normalize_idx(idx) when is_integer(idx), do: idx

  @doc """
  Creates a text placeholder shape addressed by the layout placeholder's own
  `{type, idx}`, as reported by `Podium.Template.inspect/1`.
  """
  @spec new({String.t(), non_neg_integer()}, Podium.rich_text()) :: t()
  def new({type, idx}, text) when is_binary(type) and is_integer(idx) do
    %__MODULE__{type: type, idx: idx, kind: :text, paragraphs: Text.normalize(text)}
  end

  @doc """
  Creates a text placeholder shape for the given placeholder name and text.
  """
  @spec new(atom(), atom(), Podium.rich_text()) :: t()
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
  Creates a picture placeholder struct addressed by the layout placeholder's own
  `{type, idx}`.

  The type is the layout placeholder's, not `"pic"`: PowerPoint leaves a
  content placeholder's `p:ph` alone when a picture is inserted into it, so a
  picture in a content placeholder is `{"obj", idx}`.
  """
  @spec new_picture({String.t(), non_neg_integer()}) :: t()
  def new_picture({type, idx}) when is_binary(type) and is_integer(idx) do
    %__MODULE__{type: type, idx: idx, kind: :picture}
  end

  @doc """
  Creates a picture placeholder struct (kind: :picture).
  """
  @spec new_picture(atom(), atom()) :: t()
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
  Creates a footer placeholder at the idx the layout uses for its footer.
  """
  @spec new_footer(String.t(), non_neg_integer()) :: t()
  def new_footer(text, idx) when is_integer(idx) do
    %__MODULE__{type: "ftr", idx: idx, kind: :footer, field_text: text}
  end

  @doc """
  Creates a date placeholder at the idx the layout uses for its date.
  """
  @spec new_date(String.t(), non_neg_integer()) :: t()
  def new_date(text, idx) when is_integer(idx) do
    %__MODULE__{type: "dt", idx: idx, kind: :date, field_text: text}
  end

  @doc """
  Creates a slide number placeholder at the idx the layout uses for its slide
  number.
  """
  @spec new_slide_number(non_neg_integer()) :: t()
  def new_slide_number(idx) when is_integer(idx) do
    %__MODULE__{type: "sldNum", idx: idx, kind: :slide_number}
  end

  @doc """
  Generates the XML for a placeholder shape.
  Dispatches based on the `:kind` field.
  """
  @spec to_xml(t(), map()) :: String.t()
  def to_xml(ph, hyperlink_rids \\ %{})

  def to_xml(%__MODULE__{kind: :text} = ph, hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    body_xml = Text.paragraphs_xml(ph.paragraphs, hyperlink_rids)

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph#{ph_attrs(ph)}/></p:nvPr>) <>
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

    ~s(<p:pic xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvPicPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvPicPr><a:picLocks noGrp="1"/></p:cNvPicPr>) <>
      ~s(<p:nvPr><p:ph#{ph_attrs(ph)}/></p:nvPr>) <>
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
      ~s(<p:nvPr><p:ph#{ph_attrs(ph)}/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escape(ph.field_text)}</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>) <>
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
      ~s(<p:nvPr><p:ph#{ph_attrs(ph)}/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escape(ph.field_text)}</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  def to_xml(%__MODULE__{kind: :slide_number} = ph, _hyperlink_rids) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    fld_id = generate_guid()

    ~s(<p:sp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="0" name=""/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph#{ph_attrs(ph)}/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      ~s(<a:p><a:fld id="#{fld_id}" type="slidenum"><a:rPr lang="en-US" smtClean="0"/><a:t>&lt;#&gt;</a:t></a:fld><a:endParaRPr lang="en-US"/></a:p>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  # Backward compat: placeholders created without :kind default to :text behavior
  def to_xml(%__MODULE__{kind: nil} = ph, hyperlink_rids) do
    to_xml(%{ph | kind: :text}, hyperlink_rids)
  end

  # `type` defaults to "obj" and `idx` to 0 in OOXML, so neither is written when
  # it holds the default. The membership checks are explicit because 0 is truthy
  # in Elixir.
  defp ph_attrs(%__MODULE__{} = ph) do
    type_attr = if ph.type in [nil, "obj"], do: "", else: ~s( type="#{ph.type}")
    idx_attr = if ph.idx in [nil, 0], do: "", else: ~s( idx="#{ph.idx}")

    type_attr <> idx_attr
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
