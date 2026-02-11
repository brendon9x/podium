defmodule Podium.NotesSlide do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.XML.Builder

  # Embed the python-pptx templates at compile time
  @priv_dir :code.priv_dir(:podium) |> to_string()
  @notes_master_template File.read!(Path.join(@priv_dir, "templates/notesMaster.xml"))
  @notes_theme_template File.read!(Path.join(@priv_dir, "templates/notesTheme.xml"))

  @doc """
  Generates the XML for a notes slide with the given text.
  """
  def to_xml(notes_text) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)

    escaped = Builder.escape(notes_text)

    Builder.xml_declaration() <>
      ~s(<p:notes xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:cSld>) <>
      ~s(<p:spTree>) <>
      ~s(<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>) <>
      ~s(<p:grpSpPr>) <>
      ~s(<a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm>) <>
      ~s(</p:grpSpPr>) <>
      slide_image_placeholder() <>
      notes_body_placeholder(escaped) <>
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

  defp notes_body_placeholder(escaped_text) do
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
      ~s(<a:p><a:r><a:rPr lang="en-US" dirty="0"/><a:t>#{escaped_text}</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>) <>
      ~s(</p:txBody>) <>
      ~s(</p:sp>)
  end

  @doc """
  Returns the notes master XML (python-pptx template embedded verbatim).
  """
  def master_xml do
    @notes_master_template
  end

  @doc """
  Returns the notes theme XML (separate theme for notes master, per python-pptx).
  """
  def theme_xml do
    @notes_theme_template
  end

  @doc """
  Generates the rels XML for the notes master (link to its own theme).
  """
  def master_rels_xml(theme_partname \\ "../theme/theme2.xml") do
    alias Podium.OPC.Relationships

    rels = Relationships.new()
    {rels, _rid} = Relationships.add(rels, Constants.rt(:theme), theme_partname)
    Relationships.to_xml(rels)
  end
end
