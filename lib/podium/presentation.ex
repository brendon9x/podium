defmodule Podium.Presentation do
  @moduledoc """
  Internal module managing presentation state, slide collection, and serialization.

  This module handles the lifecycle of a presentation: creating from a template,
  adding slides, and building the final OPC package. Index allocation for slides,
  charts, images, and media is deferred to serialization time via `resolve_indices/1`.
  Most users interact through the `Podium` facade module.
  """

  alias Podium.Chart
  alias Podium.Chart.{XlsxWriter, XmlWriter}

  alias Podium.{
    CoreProperties,
    Image,
    NotesSlide,
    Placeholder,
    Slide,
    Template,
    Units,
    Video
  }

  alias Podium.OPC.{Constants, ContentTypes, Package, PresentationXml, Relationships}

  @default_slide_width 12_192_000
  @default_slide_height 6_858_000
  @default_notes_master_partname "ppt/notesMasters/notesMaster1.xml"

  @core_prop_keys [
    :title,
    :author,
    :subject,
    :keywords,
    :category,
    :comments,
    :last_modified_by,
    :created,
    :modified,
    :last_printed,
    :revision,
    :content_status,
    :language,
    :version
  ]

  defstruct [
    :template_parts,
    :content_types,
    slides: [],
    pres_rels: nil,
    template: :bundled,
    template_width: @default_slide_width,
    slide_width: @default_slide_width,
    slide_height: @default_slide_height,
    core_properties: nil,
    footer: nil,
    template_info: nil,
    notes_master_created: false,
    notes_master_rid: nil,
    notes_master_partname: @default_notes_master_partname,
    notes_count: 0
  ]

  @type t :: %__MODULE__{
          template_parts: map() | nil,
          content_types: Podium.OPC.ContentTypes.t() | nil,
          slides: [Podium.Slide.t()],
          pres_rels: Podium.OPC.Relationships.t() | nil,
          template: :bundled | :custom,
          template_width: non_neg_integer(),
          slide_width: non_neg_integer(),
          slide_height: non_neg_integer(),
          core_properties: Podium.CoreProperties.t() | nil,
          footer: keyword() | nil,
          template_info: Podium.Template.t() | nil,
          notes_master_created: boolean(),
          notes_master_rid: String.t() | nil,
          notes_master_partname: String.t(),
          notes_count: non_neg_integer()
        }

  @doc """
  Creates a new presentation from the default template.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {:ok, parts} = Package.read_default_template()

    prs = from_parts(parts, :bundled, opts)

    %{
      prs
      | slide_width: Units.to_emu(Keyword.get(opts, :slide_width, @default_slide_width)),
        slide_height: Units.to_emu(Keyword.get(opts, :slide_height, @default_slide_height))
    }
  end

  @doc """
  Creates a new presentation from an arbitrary template package.

  `source` is either a path to a `.pptx`/`.potx` file or its bytes. The slide
  size is taken from the template and coordinates are never scaled. The template
  must contain no slides.
  """
  @spec from_template(binary(), keyword()) :: t()
  def from_template(source, opts \\ []) when is_binary(source) do
    parts =
      case Package.read_source(source) do
        {:ok, parts} ->
          parts

        {:error, reason} ->
          raise ArgumentError, "could not read template package: #{inspect(reason)}"
      end

    validate_template!(parts)
    from_parts(parts, :custom, opts)
  end

  defp validate_template!(parts) do
    for required <- [
          "ppt/presentation.xml",
          "[Content_Types].xml",
          "ppt/_rels/presentation.xml.rels"
        ],
        not Map.has_key?(parts, required) do
      raise ArgumentError, "template package is missing #{required}"
    end

    slide_parts = Enum.filter(Map.keys(parts), &String.starts_with?(&1, "ppt/slides/"))

    if slide_parts != [] do
      raise ArgumentError,
            "template must contain no slides, found: #{Enum.sort(slide_parts) |> Enum.join(", ")}"
    end

    rels = Relationships.parse(to_string(Map.fetch!(parts, "ppt/_rels/presentation.xml.rels")))

    if Relationships.find_by_type(rels, Constants.rt(:slide)) do
      raise ArgumentError,
            "template must contain no slides, found a slide relationship in " <>
              "ppt/_rels/presentation.xml.rels"
    end

    unless Relationships.find_by_type(rels, Constants.rt(:slide_master)) do
      raise ArgumentError, "template has no slide master; slides have no layouts to sit on"
    end

    :ok
  end

  defp from_parts(parts, template, opts) do
    pres_xml = to_string(Map.fetch!(parts, "ppt/presentation.xml"))
    content_types = ContentTypes.parse(to_string(Map.fetch!(parts, "[Content_Types].xml")))

    pres_rels =
      Relationships.parse(to_string(Map.fetch!(parts, "ppt/_rels/presentation.xml.rels")))

    {template_width, template_height} =
      PresentationXml.slide_size(pres_xml) || {@default_slide_width, @default_slide_height}

    core_opts = Keyword.take(opts, @core_prop_keys)
    core_properties = if core_opts == [], do: nil, else: CoreProperties.new(core_opts)

    {notes_master_created, notes_master_rid, notes_master_partname} =
      case Relationships.find_by_type(pres_rels, Constants.rt(:notes_master)) do
        {rid, target} -> {true, rid, normalise_pres_target(target)}
        nil -> {false, nil, @default_notes_master_partname}
      end

    template_info =
      case template do
        :bundled -> Template.bundled()
        :custom -> Template.inspect(parts)
      end

    %__MODULE__{
      template_parts: parts,
      content_types: content_types,
      pres_rels: pres_rels,
      template: template,
      template_info: template_info,
      template_width: template_width,
      slide_width: template_width,
      slide_height: template_height,
      core_properties: core_properties,
      notes_master_created: notes_master_created,
      notes_master_rid: notes_master_rid,
      notes_master_partname: notes_master_partname
    }
  end

  defp normalise_pres_target(target), do: Package.resolve_partname("ppt/presentation.xml", target)

  @doc """
  Adds a slide to the presentation. Returns the updated presentation.

  Raises when the template has no layout at the slide's layout index, or when a
  placeholder on the slide does not match one the layout defines.
  """
  @spec add_slide(t(), Podium.Slide.t()) :: t()
  def add_slide(%__MODULE__{} = prs, %Slide{} = slide) do
    layout_partname = "ppt/slideLayouts/slideLayout#{slide.layout_index}.xml"

    unless Map.has_key?(prs.template_parts, layout_partname) do
      raise ArgumentError,
            "template has no #{layout_partname} for layout #{inspect(slide.layout_index)}"
    end

    validate_slide_placeholders!(prs, slide)

    %{prs | slides: prs.slides ++ [slide]}
  end

  # Footer, date and slide number chrome is injected at build time from the
  # layout itself, so it is not among the placeholders checked here.
  defp validate_slide_placeholders!(prs, slide) do
    picture_phs = Enum.map(slide.picture_placeholders, fn {ph, _binary, _ext} -> ph end)

    for ph <- slide.placeholders ++ picture_phs do
      validate_placeholder_ref!(prs, slide.layout_index, ph)
    end

    :ok
  end

  defp validate_placeholder_ref!(prs, layout_index, ph) do
    {type, idx} = Placeholder.normalize_ref(ph)

    case Template.placeholder_by_idx(prs.template_info, layout_index, idx) do
      nil ->
        raise ArgumentError,
              "layout #{layout_index} has no placeholder with idx #{idx}; " <>
                "inspect the template with Podium.Template.inspect/1 to see what it defines"

      %{type: ^type} ->
        :ok

      %{type: actual} ->
        raise ArgumentError,
              "layout #{layout_index} placeholder idx #{idx} has type #{inspect(actual)}, " <>
                "not #{inspect(type)}"
    end
  end

  @doc """
  Sets presentation-level footer, date, and slide number options.
  """
  @spec set_footer(t(), keyword()) :: t()
  def set_footer(%__MODULE__{} = prs, opts) when is_list(opts) do
    %{prs | footer: opts}
  end

  @doc """
  Sets notes text on a slide. Returns the updated slide.
  """
  @spec set_notes(Podium.Slide.t(), String.t()) :: Podium.Slide.t()
  def set_notes(%Slide{} = slide, text) when is_binary(text) do
    %{slide | notes_text: text}
  end

  @doc """
  Places a chart into a content placeholder. Returns the updated slide.

  The placeholder is addressed either by a bundled-template name or by the
  `{type, idx}` pair `Podium.Template.inspect/1` reports for it. Position and
  size are taken from the layout.
  """
  @spec set_chart_placeholder(
          t(),
          Podium.Slide.t(),
          atom() | {String.t(), non_neg_integer()},
          atom(),
          struct(),
          keyword()
        ) :: Podium.Slide.t()
  def set_chart_placeholder(
        %__MODULE__{} = prs,
        %Slide{} = slide,
        ref,
        chart_type,
        chart_data,
        opts
      ) do
    box = placeholder_box!(prs, slide, ref, "set_chart_placeholder/6")

    chart_opts =
      opts
      |> Keyword.drop([:x, :y, :width, :height])
      |> Keyword.merge(x: box.x, y: box.y, width: box.w, height: box.h)

    Slide.add_chart(slide, chart_type, chart_data, chart_opts)
  end

  @doc """
  Places a table into a content placeholder. Returns the updated slide.

  The placeholder is addressed either by a bundled-template name or by the
  `{type, idx}` pair `Podium.Template.inspect/1` reports for it. Position and
  size are taken from the layout.
  """
  @spec set_table_placeholder(
          t(),
          Podium.Slide.t(),
          atom() | {String.t(), non_neg_integer()},
          [[term()]],
          keyword()
        ) :: Podium.Slide.t()
  def set_table_placeholder(%__MODULE__{} = prs, %Slide{} = slide, ref, rows, opts \\ []) do
    box = placeholder_box!(prs, slide, ref, "set_table_placeholder/5")

    table_opts =
      opts
      |> Keyword.drop([:x, :y, :width, :height])
      |> Keyword.merge(x: box.x, y: box.y, width: box.w, height: box.h)

    Slide.add_table(slide, rows, table_opts)
  end

  # The name path is the bundled template's; the {type, idx} path works on any
  # template. Both end at the layout placeholder's own box, scaled.
  defp placeholder_box!(prs, slide, name, fun) when is_atom(name) do
    validate_bundled_template!(prs, fun)
    layout = Slide.layout_atom(slide.layout_index)
    validate_content_placeholder!(layout, name)

    definition = Map.fetch!(Placeholder.placeholders_for(layout), name)

    box_for_ref!(prs, slide.layout_index, definition, inspect(name))
  end

  defp placeholder_box!(prs, slide, {type, idx} = ref, _fun)
       when is_binary(type) and is_integer(idx) do
    box_for_ref!(prs, slide.layout_index, ref, inspect(ref))
  end

  @chrome_types ["title", "ctrTitle", "subTitle", "dt", "ftr", "sldNum"]

  defp box_for_ref!(prs, layout_index, ref, label) do
    {type, idx} = Placeholder.normalize_ref(ref)

    ph =
      Template.placeholder(prs.template_info, layout_index, {type, idx}) ||
        raise ArgumentError,
              "layout #{layout_index} has no placeholder #{inspect({type, idx})}; " <>
                "inspect the template with Podium.Template.inspect/1 to see what it defines"

    if ph.type in @chrome_types do
      raise ArgumentError,
            "placeholder #{label} has type #{inspect(ph.type)}; " <>
              "only content placeholders accept charts/tables"
    end

    box =
      ph.box ||
        raise ArgumentError,
              "could not resolve position for placeholder #{label} on layout #{layout_index}"

    scale_box(prs, box)
  end

  defp validate_bundled_template!(%__MODULE__{template: :bundled}, _fun), do: :ok

  defp validate_bundled_template!(%__MODULE__{template: :custom}, fun) do
    raise ArgumentError,
          "#{fun} addresses placeholders by the bundled template's names and is not " <>
            "available for a presentation created with Podium.from_template/2; " <>
            "address the placeholder by the {type, idx} pair that " <>
            "Podium.Template.inspect/1 reports instead"
  end

  defp validate_content_placeholder!(layout, name) do
    defs = Placeholder.placeholders_for(layout)

    case Map.get(defs, name) do
      nil ->
        raise ArgumentError,
              "unknown placeholder #{inspect(name)} for layout #{inspect(layout)}"

      %{type: nil} ->
        :ok

      %{type: type} ->
        raise ArgumentError,
              "placeholder #{inspect(name)} has type #{inspect(type)}; " <>
                "only content placeholders accept charts/tables"
    end
  end

  defp scale_box(%__MODULE__{} = prs, %{x: x, y: y, w: w, h: h}) do
    if prs.slide_width == prs.template_width do
      %{x: x, y: y, w: w, h: h}
    else
      scale = prs.slide_width / prs.template_width
      %{x: round(x * scale), y: y, w: round(w * scale), h: h}
    end
  end

  @doc """
  Sets core document properties (Dublin Core metadata).
  """
  @spec set_core_properties(t(), keyword()) :: t()
  def set_core_properties(%__MODULE__{} = prs, opts) when is_list(opts) do
    %{prs | core_properties: CoreProperties.new(opts)}
  end

  @doc """
  Replaces a slide in the presentation (by matching slide ref).
  """
  @spec put_slide(t(), Podium.Slide.t()) :: t()
  def put_slide(%__MODULE__{} = prs, %Slide{} = slide) do
    slides =
      Enum.map(prs.slides, fn existing ->
        if existing.ref == slide.ref, do: slide, else: existing
      end)

    %{prs | slides: slides}
  end

  @doc """
  Saves the presentation to a file.
  """
  @spec save(t(), String.t()) :: :ok | {:error, term()}
  def save(%__MODULE__{} = prs, path) do
    parts = build_parts(prs)
    Package.write(parts, path)
  end

  @doc """
  Saves the presentation to an in-memory binary.
  """
  @spec save_to_memory(t()) :: {:ok, binary()} | {:error, term()}
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

  defp detect_fill_extension(<<0x89, 0x50, 0x4E, 0x47, _::binary>>), do: "png"
  defp detect_fill_extension(<<0xFF, 0xD8, _::binary>>), do: "jpeg"
  defp detect_fill_extension(<<0x42, 0x4D, _::binary>>), do: "bmp"
  defp detect_fill_extension(<<0x47, 0x49, 0x46, _::binary>>), do: "gif"
  defp detect_fill_extension(_), do: "png"

  defp next_theme_index(parts) do
    parts
    |> Map.keys()
    |> Enum.flat_map(fn path ->
      case Regex.run(~r{^ppt/theme/theme(\d+)\.xml$}, path) do
        [_, digits] -> [String.to_integer(digits)]
        nil -> []
      end
    end)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  # --- Index resolution at serialization time ---

  defp resolve_indices(prs) do
    acc = %{
      next_slide: 1,
      next_chart: 1,
      next_image: 1,
      next_media: 1,
      image_hashes: %{},
      media_hashes: %{},
      content_types: prs.content_types,
      pres_rels: prs.pres_rels
    }

    {slides, acc} = Enum.map_reduce(prs.slides, acc, &resolve_slide/2)

    %{
      prs
      | slides: slides,
        content_types: acc.content_types,
        pres_rels: acc.pres_rels
    }
  end

  defp resolve_slide(slide, acc) do
    slide_index = acc.next_slide

    # Add slide relationship to presentation
    {pres_rels, rid} =
      Relationships.add(acc.pres_rels, Constants.rt(:slide), "slides/slide#{slide_index}.xml")

    slide = %{slide | index: slide_index, pres_rid: rid}

    # Register slide content type override
    content_types =
      ContentTypes.add_override(
        acc.content_types,
        "/ppt/slides/slide#{slide_index}.xml",
        Constants.ct(:slide)
      )

    acc = %{acc | next_slide: slide_index + 1, pres_rels: pres_rels, content_types: content_types}

    # Assign chart indices
    {charts, acc} =
      Enum.map_reduce(slide.charts, acc, fn chart, a ->
        idx = a.next_chart

        ct =
          a.content_types
          |> ContentTypes.add_override("/ppt/charts/chart#{idx}.xml", Constants.ct(:chart))
          |> ContentTypes.add_default("xlsx", Constants.ct(:xlsx))

        {%{chart | chart_index: idx}, %{a | next_chart: idx + 1, content_types: ct}}
      end)

    slide = %{slide | charts: charts}

    # Assign image indices with SHA1 dedup
    {images, acc} =
      Enum.map_reduce(slide.images, acc, fn image, a ->
        case Map.get(a.image_hashes, image.sha1) do
          nil ->
            idx = a.next_image
            hashes = Map.put(a.image_hashes, image.sha1, idx)

            ct =
              ContentTypes.add_default(
                a.content_types,
                image.extension,
                content_type(image.extension)
              )

            {%{image | image_index: idx},
             %{a | next_image: idx + 1, image_hashes: hashes, content_types: ct}}

          existing_idx ->
            ct =
              ContentTypes.add_default(
                a.content_types,
                image.extension,
                content_type(image.extension)
              )

            {%{image | image_index: existing_idx}, %{a | content_types: ct}}
        end
      end)

    slide = %{slide | images: images}

    # Assign picture placeholder indices with SHA1 dedup (shared image hash space)
    {picture_placeholders, acc} =
      Enum.map_reduce(slide.picture_placeholders, acc, fn {ph, binary, ext}, a ->
        sha1 = :crypto.hash(:sha, binary) |> Base.encode16(case: :lower)

        case Map.get(a.image_hashes, sha1) do
          nil ->
            idx = a.next_image
            hashes = Map.put(a.image_hashes, sha1, idx)

            ct = ContentTypes.add_default(a.content_types, ext, content_type(ext))

            {{ph, binary, ext, idx},
             %{a | next_image: idx + 1, image_hashes: hashes, content_types: ct}}

          existing_idx ->
            ct = ContentTypes.add_default(a.content_types, ext, content_type(ext))
            {{ph, binary, ext, existing_idx}, %{a | content_types: ct}}
        end
      end)

    slide = %{slide | picture_placeholders: picture_placeholders}

    # Assign video media indices with SHA1 dedup + poster image indices
    {videos, acc} =
      Enum.map_reduce(slide.videos, acc, fn video, a ->
        # Dedup media by SHA1
        {media_idx, a} =
          case Map.get(a.media_hashes, video.sha1) do
            nil ->
              idx = a.next_media
              hashes = Map.put(a.media_hashes, video.sha1, idx)
              {idx, %{a | next_media: idx + 1, media_hashes: hashes}}

            existing_idx ->
              {existing_idx, a}
          end

        # Dedup poster frame image by SHA1
        poster = video.poster_frame
        poster_sha1 = :crypto.hash(:sha, poster.binary) |> Base.encode16(case: :lower)

        {poster_idx, a} =
          case Map.get(a.image_hashes, poster_sha1) do
            nil ->
              idx = a.next_image
              hashes = Map.put(a.image_hashes, poster_sha1, idx)
              {idx, %{a | next_image: idx + 1, image_hashes: hashes}}

            existing_idx ->
              {existing_idx, a}
          end

        # Register content types
        ct =
          a.content_types
          |> ContentTypes.add_default(video.extension, video.mime_type)
          |> ContentTypes.add_default(poster.extension, content_type(poster.extension))

        video = %{
          video
          | media_index: media_idx,
            poster_frame: %{poster | image_index: poster_idx}
        }

        {video, %{a | content_types: ct}}
      end)

    slide = %{slide | videos: videos}

    # Register background image extension content type
    acc =
      case slide.background_image do
        {_binary, ext} ->
          ct = ContentTypes.add_default(acc.content_types, ext, content_type(ext))
          %{acc | content_types: ct}

        nil ->
          acc
      end

    # Register fill image extension content types
    acc =
      Enum.reduce(slide.fill_images, acc, fn {_shape_id, binary, _ext}, a ->
        ext = detect_fill_extension(binary)
        ct = ContentTypes.add_default(a.content_types, ext, content_type(ext))
        %{a | content_types: ct}
      end)

    {slide, acc}
  end

  defp build_parts(%__MODULE__{} = prs) do
    # Resolve all indices at serialization time
    prs = resolve_indices(prs)

    parts = scale_layout_coordinates(prs.template_parts, prs.slide_width, prs.template_width)

    # Build ref_to_index map for slide jump resolution
    ref_to_index = Map.new(prs.slides, &{&1.ref, &1.index})

    # Process each slide: generate slide XML, slide rels, chart parts, image parts
    {parts, prs} =
      Enum.reduce(prs.slides, {parts, prs}, fn slide, {acc, prs_acc} ->
        build_slide_parts(slide, acc, prs_acc, ref_to_index)
      end)

    # Edit the template's presentation.xml in place
    parts = Map.put(parts, "ppt/presentation.xml", build_presentation_xml(prs, parts))

    # Update presentation rels
    parts =
      Map.put(parts, "ppt/_rels/presentation.xml.rels", Relationships.to_xml(prs.pres_rels))

    # Podium always writes a presentation, never a template (.potx)
    content_types =
      ContentTypes.add_override(
        prs.content_types,
        "/ppt/presentation.xml",
        Constants.ct(:presentation)
      )

    # Replace core properties if set. The template's own `_rels/.rels` is
    # expected to already carry the core-properties relationship, which any
    # package saved by PowerPoint does.
    {parts, content_types} =
      if prs.core_properties do
        {Map.put(parts, "docProps/core.xml", CoreProperties.to_xml(prs.core_properties)),
         ContentTypes.add_override(
           content_types,
           "/docProps/core.xml",
           Constants.ct(:core_properties)
         )}
      else
        {parts, content_types}
      end

    Map.put(parts, "[Content_Types].xml", ContentTypes.to_xml(content_types))
  end

  defp build_slide_parts(slide, parts, prs, ref_to_index) do
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

    # Add fill image relationships and store fill image binaries
    {slide_rels, fill_rids, parts} =
      Enum.reduce(slide.fill_images, {slide_rels, %{}, parts}, fn {shape_id, binary, ext},
                                                                  {rels, rids, acc} ->
        fill_index = map_size(rids) + 1
        fill_media_name = "fill_image#{slide.index}_#{fill_index}.#{ext}"

        {rels, fill_rid} =
          Relationships.add(rels, Constants.rt(:image), "../media/#{fill_media_name}")

        acc = Map.put(acc, "ppt/media/#{fill_media_name}", binary)
        rids = Map.put(rids, shape_id, fill_rid)

        {rels, rids, acc}
      end)

    # Add background image relationship if present
    {slide_rels, bg_rid, parts} =
      case slide.background_image do
        {binary, ext} ->
          bg_media_name = "bg_image#{slide.index}.#{ext}"

          {rels, rid} =
            Relationships.add(slide_rels, Constants.rt(:image), "../media/#{bg_media_name}")

          parts = Map.put(parts, "ppt/media/#{bg_media_name}", binary)
          {rels, rid, parts}

        nil ->
          {slide_rels, nil, parts}
      end

    # Add picture placeholder relationships and store image binaries
    {slide_rels, slide, parts} =
      Enum.reduce(
        slide.picture_placeholders,
        {slide_rels, slide, parts},
        fn {ph, binary, ext, img_index}, {rels, sl, acc} ->
          {rels, pic_rid} =
            Relationships.add(
              rels,
              Constants.rt(:image),
              "../media/image#{img_index}.#{ext}"
            )

          acc = Map.put(acc, "ppt/media/image#{img_index}.#{ext}", binary)

          # Set image_rid on the placeholder and add to slide.placeholders
          ph = %{ph | image_rid: pic_rid}
          sl = %{sl | placeholders: sl.placeholders ++ [ph]}

          {rels, sl, acc}
        end
      )

    # Add video relationships and store video/poster binaries
    {slide_rels, video_rids, parts} =
      Enum.reduce(slide.videos, {slide_rels, [], parts}, fn video, {rels, rids, acc} ->
        # RT.VIDEO relationship (r:link - external-style, target on media file)
        {rels, video_rid} =
          Relationships.add(
            rels,
            Constants.rt(:video),
            "../media/media#{video.media_index}.#{video.extension}"
          )

        # RT.MEDIA relationship (r:embed - for p14:media)
        {rels, media_rid} =
          Relationships.add(
            rels,
            Constants.rt(:media),
            "../media/media#{video.media_index}.#{video.extension}"
          )

        # RT.IMAGE relationship for poster frame
        poster = video.poster_frame

        {rels, poster_rid} =
          Relationships.add(
            rels,
            Constants.rt(:image),
            "../media/image#{poster.image_index}.#{poster.extension}"
          )

        # Store media and poster binaries
        acc = Map.put(acc, Video.media_partname(video), video.binary)
        acc = Map.put(acc, Video.poster_partname(video), poster.binary)

        {rels, rids ++ [{video, video_rid, media_rid, poster_rid}], acc}
      end)

    # Collect hyperlink URLs from all shapes and placeholders, create external rels
    all_hyperlink_urls = collect_all_hyperlink_urls(slide)

    {slide_rels, hyperlink_rids} =
      Enum.reduce(all_hyperlink_urls, {slide_rels, %{}}, fn url, {rels, rids} ->
        {rels, rid} = Relationships.add(rels, Constants.rt(:hyperlink), url, true)
        {rels, Map.put(rids, url, rid)}
      end)

    # Collect slide jump targets and create internal slide relationships
    all_slide_jumps = collect_all_slide_jumps(slide)

    {slide_rels, hyperlink_rids} =
      Enum.reduce(all_slide_jumps, {slide_rels, hyperlink_rids}, fn ref, {rels, rids} ->
        target_idx = Map.fetch!(ref_to_index, ref)

        {rels, rid} =
          Relationships.add(rels, Constants.rt(:slide), "../slides/slide#{target_idx}.xml")

        {rels, Map.put(rids, {:slide_jump, ref}, rid)}
      end)

    # Inject footer/date/slide_number placeholders if set
    slide =
      if prs.footer do
        inject_footer_placeholders(slide, prs.footer, prs.template_info)
      else
        slide
      end

    # Handle notes slide
    {slide_rels, parts, prs} =
      if slide.notes_text do
        build_notes_parts(slide, slide_rels, parts, prs)
      else
        {slide_rels, parts, prs}
      end

    # Generate slide XML with chart, image, fill, hyperlink, video relationship IDs
    parts =
      Map.put(
        parts,
        Slide.partname(slide),
        Slide.to_xml(slide, chart_rids, image_rids, fill_rids, hyperlink_rids, bg_rid, video_rids)
      )

    parts = Map.put(parts, Slide.rels_partname(slide), Relationships.to_xml(slide_rels))

    {parts, prs}
  end

  defp collect_all_hyperlink_urls(slide) do
    shape_urls =
      Enum.flat_map(slide.shapes, fn shape ->
        Podium.Text.collect_hyperlink_urls(shape.paragraphs || [])
      end)

    placeholder_urls =
      Enum.flat_map(slide.placeholders, fn ph ->
        case ph.kind do
          :text -> Podium.Text.collect_hyperlink_urls(ph.paragraphs || [])
          _ -> []
        end
      end)

    (shape_urls ++ placeholder_urls) |> Enum.uniq()
  end

  defp collect_all_slide_jumps(slide) do
    shape_jumps =
      Enum.flat_map(slide.shapes, fn shape ->
        Podium.Text.collect_slide_jumps(shape.paragraphs || [])
      end)

    placeholder_jumps =
      Enum.flat_map(slide.placeholders, fn ph ->
        case ph.kind do
          :text -> Podium.Text.collect_slide_jumps(ph.paragraphs || [])
          _ -> []
        end
      end)

    (shape_jumps ++ placeholder_jumps) |> Enum.uniq()
  end

  defp build_notes_parts(slide, slide_rels, parts, prs) do
    n = prs.notes_count + 1
    prs = %{prs | notes_count: n}

    # Lazily create notes master (once per presentation)
    {parts, prs} =
      if prs.notes_master_created do
        {parts, prs}
      else
        # Determine notes theme partname (next available theme index)
        theme_index = next_theme_index(parts)
        theme_partname = "ppt/theme/theme#{theme_index}.xml"

        # Add notesMaster parts
        parts = Map.put(parts, "ppt/notesMasters/notesMaster1.xml", NotesSlide.master_xml())

        parts =
          Map.put(
            parts,
            "ppt/notesMasters/_rels/notesMaster1.xml.rels",
            NotesSlide.master_rels_xml("../theme/theme#{theme_index}.xml")
          )

        # Add separate theme for notes master (python-pptx pattern)
        parts = Map.put(parts, theme_partname, NotesSlide.theme_xml())

        # Add presentation -> notesMaster relationship
        {pres_rels, nm_rid} =
          Relationships.add(
            prs.pres_rels,
            Constants.rt(:notes_master),
            "notesMasters/notesMaster1.xml"
          )

        # Add content type overrides for notesMaster and its theme
        content_types =
          prs.content_types
          |> ContentTypes.add_override(
            "/ppt/notesMasters/notesMaster1.xml",
            Constants.ct(:notes_master)
          )
          |> ContentTypes.add_override(
            "/#{theme_partname}",
            Constants.ct(:theme)
          )

        prs = %{
          prs
          | pres_rels: pres_rels,
            content_types: content_types,
            notes_master_created: true,
            notes_master_rid: nm_rid
        }

        {parts, prs}
      end

    # Create notesSlide XML
    parts =
      Map.put(parts, "ppt/notesSlides/notesSlide#{n}.xml", NotesSlide.to_xml(slide.notes_text))

    # Create notesSlide rels (references slide + notesMaster)
    notes_rels = Relationships.new()

    {notes_rels, _slide_rid} =
      Relationships.add(notes_rels, Constants.rt(:slide), "../slides/slide#{slide.index}.xml")

    {notes_rels, _master_rid} =
      Relationships.add(
        notes_rels,
        Constants.rt(:notes_master),
        "../" <> Path.relative_to(prs.notes_master_partname, "ppt")
      )

    parts =
      Map.put(
        parts,
        "ppt/notesSlides/_rels/notesSlide#{n}.xml.rels",
        Relationships.to_xml(notes_rels)
      )

    # Add slide -> notesSlide relationship
    {slide_rels, _notes_rid} =
      Relationships.add(
        slide_rels,
        Constants.rt(:notes_slide),
        "../notesSlides/notesSlide#{n}.xml"
      )

    # Add content type override for this notesSlide
    content_types =
      ContentTypes.add_override(
        prs.content_types,
        "/ppt/notesSlides/notesSlide#{n}.xml",
        Constants.ct(:notes_slide)
      )

    prs = %{prs | content_types: content_types}

    {slide_rels, parts, prs}
  end

  # PowerPoint only shows footer, date or slide number on a slide that carries
  # the placeholder itself, and at the idx its layout uses. A layout without one
  # of them gets nothing.
  defp inject_footer_placeholders(slide, opts, template_info) do
    layout_idx = fn type ->
      case Template.placeholder_by_type(template_info, slide.layout_index, type) do
        nil -> nil
        ph -> ph.idx
      end
    end

    placeholders =
      slide.placeholders
      |> append_chrome(Keyword.get(opts, :footer), layout_idx.("ftr"), &Placeholder.new_footer/2)
      |> append_chrome(Keyword.get(opts, :date), layout_idx.("dt"), &Placeholder.new_date/2)

    placeholders =
      case {Keyword.get(opts, :slide_number, false), layout_idx.("sldNum")} do
        {true, idx} when is_integer(idx) -> placeholders ++ [Placeholder.new_slide_number(idx)]
        _ -> placeholders
      end

    %{slide | placeholders: placeholders}
  end

  defp append_chrome(placeholders, nil, _idx, _build), do: placeholders
  defp append_chrome(placeholders, _text, nil, _build), do: placeholders

  defp append_chrome(placeholders, text, idx, build) when is_integer(idx) do
    placeholders ++ [build.(text, idx)]
  end

  # Edits the template's own presentation.xml rather than regenerating it, so
  # the template's notes size, default text style and any other settings survive.
  defp build_presentation_xml(%__MODULE__{} = prs, parts) do
    slide_id_entries =
      prs.slides
      |> Enum.with_index()
      |> Enum.map(fn {slide, idx} -> {256 + idx, slide.pres_rid} end)

    parts
    |> Map.fetch!("ppt/presentation.xml")
    |> to_string()
    |> PresentationXml.strip_section_list()
    |> PresentationXml.put_slide_id_list(slide_id_entries)
    |> put_notes_master_id(prs)
    |> put_slide_size(prs)
  end

  defp put_notes_master_id(xml, %__MODULE__{notes_master_rid: nil}), do: xml

  defp put_notes_master_id(xml, %__MODULE__{notes_master_rid: rid}) do
    PresentationXml.put_notes_master_id(xml, rid)
  end

  defp put_slide_size(xml, %__MODULE__{} = prs) do
    if PresentationXml.slide_size(xml) == {prs.slide_width, prs.slide_height} do
      xml
    else
      PresentationXml.put_slide_size(xml, prs.slide_width, prs.slide_height)
    end
  end

  # --- Template coordinate scaling ---
  # The bundled template is 4:3 (9,144,000 EMU wide). When the presentation uses
  # a different width (e.g. 16:9 = 12,192,000), we scale horizontal coordinates
  # in the slide layout and slide master XMLs so placeholders fill the slide.
  # A presentation built from a custom template keeps its own width, so nothing
  # is scaled.

  defp scale_layout_coordinates(parts, slide_width, template_width)
       when slide_width == template_width,
       do: parts

  defp scale_layout_coordinates(parts, slide_width, template_width) do
    scale = slide_width / template_width

    Map.new(parts, fn {path, data} ->
      if layout_or_master_xml?(path) do
        {path, scale_xml_x(to_string(data), scale)}
      else
        {path, data}
      end
    end)
  end

  defp layout_or_master_xml?(path) do
    String.ends_with?(path, ".xml") and
      (String.contains?(path, "slideLayout") or String.contains?(path, "slideMaster"))
  end

  defp scale_xml_x(xml, scale) do
    xml
    |> scale_attr("a:off", "x", scale)
    |> scale_attr("a:ext", "cx", scale)
    |> scale_attr("a:chOff", "x", scale)
    |> scale_attr("a:chExt", "cx", scale)
  end

  defp scale_attr(xml, element, attr, scale) do
    pattern = Regex.compile!("<#{Regex.escape(element)} #{attr}=\"(\\d+)\"")

    Regex.replace(pattern, xml, fn _full, value_str ->
      scaled = round(String.to_integer(value_str) * scale)
      ~s(<#{element} #{attr}="#{scaled}")
    end)
  end
end
