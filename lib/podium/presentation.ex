defmodule Podium.Presentation do
  @moduledoc false

  alias Podium.Chart
  alias Podium.Chart.{XlsxWriter, XmlWriter}
  alias Podium.{CoreProperties, Image, Slide, Units}
  alias Podium.OPC.{Constants, ContentTypes, Package, Relationships}

  @blank_layout_index 7

  @default_slide_width 12_192_000
  @default_slide_height 6_858_000

  defstruct [
    :template_parts,
    :content_types,
    slides: [],
    next_slide_index: 1,
    next_chart_index: 1,
    next_image_index: 1,
    image_hashes: %{},
    pres_rels: nil,
    slide_width: @default_slide_width,
    slide_height: @default_slide_height,
    core_properties: nil
  ]

  @doc """
  Creates a new presentation from the default template.
  """
  def new(opts \\ []) do
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

    slide_width = Units.to_emu(Keyword.get(opts, :slide_width, @default_slide_width))
    slide_height = Units.to_emu(Keyword.get(opts, :slide_height, @default_slide_height))

    core_prop_keys = [
      :title,
      :author,
      :subject,
      :keywords,
      :category,
      :comments,
      :last_modified_by
    ]

    core_opts = Keyword.take(opts, core_prop_keys)

    core_properties =
      if core_opts == [], do: nil, else: CoreProperties.new(core_opts)

    %__MODULE__{
      template_parts: parts,
      content_types: ContentTypes.from_template(),
      pres_rels: pres_rels,
      slide_width: slide_width,
      slide_height: slide_height,
      core_properties: core_properties
    }
  end

  @doc """
  Adds a new blank slide and returns the updated presentation with the slide.
  """
  def add_slide(%__MODULE__{} = prs, opts \\ []) do
    layout =
      cond do
        Keyword.has_key?(opts, :layout) -> Keyword.get(opts, :layout)
        Keyword.has_key?(opts, :layout_index) -> Keyword.get(opts, :layout_index)
        true -> @blank_layout_index
      end

    layout_index = resolve_layout_index(layout)
    slide_index = prs.next_slide_index

    # Add slide relationship to presentation — store the assigned rId
    {pres_rels, rid} =
      Relationships.add(prs.pres_rels, Constants.rt(:slide), "slides/slide#{slide_index}.xml")

    background = Keyword.get(opts, :background)
    slide = Slide.new(index: slide_index, layout_index: layout_index)
    slide = %{slide | pres_rid: rid, background: background}

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
  The slide is automatically updated within the presentation.
  """
  def add_chart(%__MODULE__{} = prs, %Slide{} = slide, chart_type, chart_data, opts) do
    chart_index = prs.next_chart_index

    slide = Slide.add_chart(slide, chart_type, chart_data, chart_index, opts)

    content_types =
      prs.content_types
      |> ContentTypes.add_override("/ppt/charts/chart#{chart_index}.xml", Constants.ct(:chart))
      |> ContentTypes.add_default("xlsx", Constants.ct(:xlsx))

    # Auto-update the slide within prs.slides
    slides = replace_slide(prs.slides, slide)

    prs = %{
      prs
      | slides: slides,
        next_chart_index: chart_index + 1,
        content_types: content_types
    }

    {prs, slide}
  end

  @doc """
  Adds an image to a slide. Returns `{presentation, slide}`.
  """
  def add_image(%__MODULE__{} = prs, %Slide{} = slide, binary, opts) do
    image_index = prs.next_image_index
    image = Image.new(binary, image_index, opts)

    # Deduplication: reuse existing image index if same binary was already added
    {image, next_index, image_hashes} =
      case Map.get(prs.image_hashes, image.sha1) do
        nil ->
          hashes = Map.put(prs.image_hashes, image.sha1, image_index)
          {image, image_index + 1, hashes}

        existing_index ->
          deduped = %{image | image_index: existing_index}
          {deduped, image_index, prs.image_hashes}
      end

    slide = Slide.add_image(slide, image)

    content_types =
      ContentTypes.add_default(prs.content_types, image.extension, content_type(image.extension))

    slides = replace_slide(prs.slides, slide)

    prs = %{
      prs
      | slides: slides,
        next_image_index: next_index,
        content_types: content_types,
        image_hashes: image_hashes
    }

    {prs, slide}
  end

  @doc """
  Sets core document properties (Dublin Core metadata).
  """
  def set_core_properties(%__MODULE__{} = prs, opts) when is_list(opts) do
    %{prs | core_properties: CoreProperties.new(opts)}
  end

  @doc """
  Replaces a slide in the presentation (by matching slide index).
  """
  def put_slide(%__MODULE__{} = prs, %Slide{} = slide) do
    %{prs | slides: replace_slide(prs.slides, slide)}
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

  defp content_type("png"), do: Constants.ct(:png)
  defp content_type("jpeg"), do: Constants.ct(:jpeg)
  defp content_type("bmp"), do: Constants.ct(:bmp)
  defp content_type("gif"), do: Constants.ct(:gif)
  defp content_type("tiff"), do: Constants.ct(:tiff)
  defp content_type("emf"), do: Constants.ct(:emf)
  defp content_type("wmf"), do: Constants.ct(:wmf)

  defp resolve_layout_index(:title_slide), do: 1
  defp resolve_layout_index(:title_content), do: 2
  defp resolve_layout_index(:blank), do: @blank_layout_index
  defp resolve_layout_index(index) when is_integer(index), do: index

  defp replace_slide(slides, %Slide{} = slide) do
    Enum.map(slides, fn existing ->
      if existing.index == slide.index, do: slide, else: existing
    end)
  end

  defp build_parts(%__MODULE__{} = prs) do
    parts = prs.template_parts

    # Process each slide: generate slide XML, slide rels, chart parts, image parts
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

    # Replace core properties if set
    parts =
      if prs.core_properties do
        Map.put(parts, "docProps/core.xml", CoreProperties.to_xml(prs.core_properties))
      else
        parts
      end

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
        chart_xml = XmlWriter.to_xml(chart)
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

    # Add image relationships and store image binaries
    {slide_rels, image_rids, parts} =
      Enum.reduce(slide.images, {slide_rels, [], parts}, fn image, {rels, rids, acc} ->
        {rels, image_rid} =
          Relationships.add(
            rels,
            Constants.rt(:image),
            "../media/image#{image.image_index}.#{image.extension}"
          )

        acc = Map.put(acc, Image.partname(image), image.binary)

        {rels, rids ++ [{image, image_rid}], acc}
      end)

    # Generate slide XML with chart and image relationship IDs
    parts = Map.put(parts, Slide.partname(slide), Slide.to_xml(slide, chart_rids, image_rids))
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
            ~s(<p:sldId id="#{slide_id}" r:id="#{slide.pres_rid}"/>)
          end)
          |> Enum.join()

        "<p:sldIdLst>#{entries}</p:sldIdLst>"
      end

    Podium.XML.Builder.xml_declaration() <>
      ~s(<p:presentation xmlns:a="#{ns_a}" xmlns:r="#{ns_r}" xmlns:p="#{ns_p}" saveSubsetFonts="1" autoCompressPictures="0">) <>
      ~s(<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>) <>
      slide_id_list <>
      ~s(<p:sldSz cx="#{prs.slide_width}" cy="#{prs.slide_height}"/>) <>
      ~s(<p:notesSz cx="#{prs.slide_height}" cy="#{prs.slide_width}"/>) <>
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
