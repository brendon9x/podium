defmodule Podium.NotesSlide do
  @moduledoc """
  Speaker notes XML generation.

  Generates notesSlide XML, notes master XML, and the associated theme
  for the notes master (following the python-pptx pattern).
  """

  alias Podium.OPC.Constants
  alias Podium.Text
  alias Podium.XML.Builder

  # Embed the python-pptx templates at compile time
  @priv_dir :code.priv_dir(:podium) |> to_string()
  @notes_master_template File.read!(Path.join(@priv_dir, "templates/notesMaster.xml"))
  @notes_theme_template File.read!(Path.join(@priv_dir, "templates/notesTheme.xml"))

  @doc """
  Generates the XML for a notes slide with the given text.

  Each line of `notes_text` becomes its own paragraph, so the spacing the
  author typed is the spacing the reader sees in the notes pane. A blank line
  becomes an empty paragraph rather than being dropped.
  """
  @spec to_xml(String.t()) :: String.t()
  def to_xml(notes_text) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)

    Builder.xml_declaration() <>
      ~s(<p:notes xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:cSld>) <>
      ~s(<p:spTree>) <>
      ~s(<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>) <>
      ~s(<p:grpSpPr>) <>
      ~s(<a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm>) <>
      ~s(</p:grpSpPr>) <>
      slide_image_placeholder() <>
      notes_body_placeholder(notes_text) <>
      ~s(</p:spTree>) <>
      ~s(</p:cSld>) <>
      ~s(<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>) <>
      ~s(</p:notes>)
  end

  defp slide_image_placeholder do
    ~s(<p:sp>) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="2" name="Slide Image Placeholder 1"/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1" noRot="1" noChangeAspect="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph type="sldImg" idx="2"/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(</p:sp>)
  end

  defp notes_body_placeholder(notes_text) do
    paragraphs =
      notes_text
      |> String.split(~r/\r?\n/)
      |> Enum.map(&line_paragraph/1)
      |> Text.normalize()
      |> Text.paragraphs_xml()

    ~s(<p:sp>) <>
      ~s(<p:nvSpPr>) <>
      ~s(<p:cNvPr id="3" name="Notes Placeholder 2"/>) <>
      ~s(<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>) <>
      ~s(<p:nvPr><p:ph type="body" sz="quarter" idx="3"/></p:nvPr>) <>
      ~s(</p:nvSpPr>) <>
      ~s(<p:spPr/>) <>
      ~s(<p:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      paragraphs <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  # An empty line is a paragraph with no runs, which `Podium.Text` renders as
  # `<a:p><a:endParaRPr/></a:p>`: a valid empty paragraph.
  defp line_paragraph(""), do: []
  defp line_paragraph(line), do: [line]

  @doc """
  Returns the notes master XML (python-pptx template embedded verbatim).
  """
  @spec master_xml() :: String.t()
  def master_xml do
    @notes_master_template
  end

  @doc """
  Returns the notes theme XML (separate theme for notes master, per python-pptx).
  """
  @spec theme_xml() :: String.t()
  def theme_xml do
    @notes_theme_template
  end

  @doc """
  Generates the rels XML for the notes master (link to its own theme).
  """
  @spec master_rels_xml(String.t()) :: String.t()
  def master_rels_xml(theme_partname \\ "../theme/theme2.xml") do
    alias Podium.OPC.Relationships

    rels = Relationships.new()
    {rels, _rid} = Relationships.add(rels, Constants.rt(:theme), theme_partname)
    Relationships.to_xml(rels)
  end
end
