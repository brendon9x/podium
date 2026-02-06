defmodule Podium.Presentation do
  @moduledoc false

  alias Podium.Chart
  alias Podium.Chart.{XlsxWriter, XmlWriter}
  alias Podium.OPC.{Constants, ContentTypes, Package, Relationships}
  alias Podium.Slide

  defstruct [
    :template_parts,
    :content_types,
    slides: [],
    next_slide_index: 1,
    next_chart_index: 1,
    pres_rels: nil
  ]

  @doc """
  Creates a new presentation from the default template.
  """
  def new do
    {:ok, parts} = Package.read_template()

    pres_rels =
      Relationships.from_list([
        {"rId1", Constants.rt(:slide_master), "slideMasters/slideMaster1.xml"},
        {"rId2", Constants.rt(:printer_settings), "printerSettings/printerSettings1.bin"},
        {"rId3", Constants.rt(:pres_props), "presProps.xml"},
        {"rId4", Constants.rt(:view_props), "viewProps.xml"},
        {"rId5", Constants.rt(:theme), "theme/theme1.xml"},
        {"rId6", Constants.rt(:table_styles), "tableStyles.xml"}
      ])

    %__MODULE__{
      template_parts: parts,
      content_types: ContentTypes.from_template(),
      pres_rels: pres_rels
    }
  end

  @doc """
  Adds a new blank slide and returns the updated presentation with the slide.
  """
  def add_slide(%__MODULE__{} = prs, opts \\ []) do
    layout_index = Keyword.get(opts, :layout_index, 7)
    slide_index = prs.next_slide_index

    slide = Slide.new(index: slide_index, layout_index: layout_index)

    {pres_rels, _rid} =
      Relationships.add(prs.pres_rels, Constants.rt(:slide), "slides/slide#{slide_index}.xml")

    content_types =
      ContentTypes.add_override(
        prs.content_types,
        "/ppt/slides/slide#{slide_index}.xml",
        Constants.ct(:slide)
      )

    prs = %{
      prs
      | slides: prs.slides ++ [slide],
        next_slide_index: slide_index + 1,
        pres_rels: pres_rels,
        content_types: content_types
    }

    {prs, slide}
  end

  @doc """
  Adds a chart to a slide and returns the updated {presentation, slide}.
  """
  def add_chart(%__MODULE__{} = prs, %Slide{} = slide, chart_type, chart_data, opts) do
    chart_index = prs.next_chart_index

    slide = Slide.add_chart(slide, chart_type, chart_data, chart_index, opts)

    # Register chart and xlsx content types
    content_types =
      prs.content_types
      |> ContentTypes.add_override("/ppt/charts/chart#{chart_index}.xml", Constants.ct(:chart))
      |> ContentTypes.add_default("xlsx", Constants.ct(:xlsx))

    prs = %{
      prs
      | next_chart_index: chart_index + 1,
        content_types: content_types
    }

    {prs, slide}
  end

  @doc """
  Replaces a slide in the presentation (by matching slide index).
  """
  def put_slide(%__MODULE__{} = prs, %Slide{} = slide) do
    slides =
      Enum.map(prs.slides, fn existing ->
        if existing.index == slide.index, do: slide, else: existing
      end)

    %{prs | slides: slides}
  end

  @doc """
  Saves the presentation to a file.
  """
  def save(%__MODULE__{} = prs, path) do
    parts = build_parts(prs)
    Package.write(parts, path)
  end

  @doc """
  Saves the presentation to an in-memory binary.
  """
  def save_to_memory(%__MODULE__{} = prs) do
    parts = build_parts(prs)
    Package.write_to_memory(parts)
  end

  defp build_parts(%__MODULE__{} = prs) do
    parts = prs.template_parts

    # Process each slide: generate slide XML, slide rels, chart parts
    parts =
      Enum.reduce(prs.slides, parts, fn slide, acc ->
        build_slide_parts(slide, acc)
      end)

    # Update presentation.xml to include slide references
    parts = Map.put(parts, "ppt/presentation.xml", build_presentation_xml(prs))

    # Update presentation rels
    parts =
      Map.put(parts, "ppt/_rels/presentation.xml.rels", Relationships.to_xml(prs.pres_rels))

    # Update content types
    parts = Map.put(parts, "[Content_Types].xml", ContentTypes.to_xml(prs.content_types))

    parts
  end

  defp build_slide_parts(slide, parts) do
    # Start with slide layout relationship
    slide_rels = Relationships.new()

    {slide_rels, _layout_rid} =
      Relationships.add(
        slide_rels,
        Constants.rt(:slide_layout),
        "../slideLayouts/slideLayout#{slide.layout_index}.xml"
      )

    # Add chart relationships and generate chart parts
    {slide_rels, chart_rids, parts} =
      Enum.reduce(slide.charts, {slide_rels, [], parts}, fn chart, {rels, rids, acc} ->
        # Add slide -> chart relationship
        {rels, chart_rid} =
          Relationships.add(rels, Constants.rt(:chart), "../charts/chart#{chart.chart_index}.xml")

        # Generate chart XML
        chart_xml = XmlWriter.to_xml(chart.chart_type, chart.chart_data)
        acc = Map.put(acc, Chart.partname(chart), chart_xml)

        # Generate chart rels (chart -> embedded xlsx)
        chart_rels = Relationships.new()

        {chart_rels, _xlsx_rid} =
          Relationships.add(
            chart_rels,
            Constants.rt(:package),
            "../embeddings/Microsoft_Excel_Sheet#{chart.chart_index}.xlsx"
          )

        acc = Map.put(acc, Chart.rels_partname(chart), Relationships.to_xml(chart_rels))

        # Generate embedded xlsx
        xlsx_binary = XlsxWriter.to_xlsx(chart.chart_data)
        acc = Map.put(acc, Chart.xlsx_partname(chart), xlsx_binary)

        {rels, rids ++ [{chart, chart_rid}], acc}
      end)

    # Generate slide XML with chart relationship IDs
    parts = Map.put(parts, Slide.partname(slide), Slide.to_xml(slide, chart_rids))
    parts = Map.put(parts, Slide.rels_partname(slide), Relationships.to_xml(slide_rels))

    parts
  end

  defp build_presentation_xml(%__MODULE__{} = prs) do
    ns_a = Constants.ns(:a)
    ns_r = Constants.ns(:r)
    ns_p = Constants.ns(:p)

    slide_id_list =
      if prs.slides == [] do
        ""
      else
        entries =
          prs.slides
          |> Enum.with_index()
          |> Enum.map(fn {slide, idx} ->
            slide_id = 256 + idx
            rid = "rId#{6 + slide.index}"
            ~s(<p:sldId id="#{slide_id}" r:id="#{rid}"/>)
          end)
          |> Enum.join()

        "<p:sldIdLst>#{entries}</p:sldIdLst>"
      end

    Podium.XML.Builder.xml_declaration() <>
      ~s(<p:presentation xmlns:a="#{ns_a}" xmlns:r="#{ns_r}" xmlns:p="#{ns_p}" saveSubsetFonts="1" autoCompressPictures="0">) <>
      ~s(<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>) <>
      slide_id_list <>
      ~s(<p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>) <>
      ~s(<p:notesSz cx="6858000" cy="9144000"/>) <>
      default_text_style_xml() <>
      ~s(</p:presentation>)
  end

  defp default_text_style_xml do
    levels =
      Enum.map(1..9, fn level ->
        mar_l = (level - 1) * 457_200

        ~s(<a:lvl#{level}pPr marL="#{mar_l}" algn="l" defTabSz="457200" rtl="0" eaLnBrk="1" latinLnBrk="0" hangingPunct="1">) <>
          ~s(<a:defRPr sz="1800" kern="1200">) <>
          ~s(<a:solidFill><a:schemeClr val="tx1"/></a:solidFill>) <>
          ~s(<a:latin typeface="+mn-lt"/><a:ea typeface="+mn-ea"/><a:cs typeface="+mn-cs"/>) <>
          ~s(</a:defRPr></a:lvl#{level}pPr>)
      end)
      |> Enum.join()

    ~s(<p:defaultTextStyle><a:defPPr><a:defRPr lang="en-US"/></a:defPPr>#{levels}</p:defaultTextStyle>)
  end
end
