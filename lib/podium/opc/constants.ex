defmodule Podium.OPC.Constants do
  @moduledoc """
  OOXML namespace URIs, relationship types, and content type constants.

  Provides `ns/1` for XML namespace URIs, `rt/1` for relationship type URIs,
  and `ct/1` for MIME content type strings used throughout the OPC package.
  """

  @doc """
  Returns the XML namespace URI for the given namespace key.

  Keys: `:a` (DrawingML), `:c` (ChartML), `:p` (PresentationML), `:r` (Relationships),
  `:ct` (Content Types), `:pr` (Package Relationships), `:dc` (Dublin Core),
  `:dcterms`, `:cp` (Core Properties), `:ep` (Extended Properties), `:mc`,
  `:xsi`, `:p14`.
  """
  @spec ns(atom()) :: String.t()
  def ns(:a), do: "http://schemas.openxmlformats.org/drawingml/2006/main"
  def ns(:c), do: "http://schemas.openxmlformats.org/drawingml/2006/chart"
  def ns(:p), do: "http://schemas.openxmlformats.org/presentationml/2006/main"
  def ns(:r), do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  def ns(:ct), do: "http://schemas.openxmlformats.org/package/2006/content-types"
  def ns(:pr), do: "http://schemas.openxmlformats.org/package/2006/relationships"
  def ns(:dc), do: "http://purl.org/dc/elements/1.1/"
  def ns(:dcterms), do: "http://purl.org/dc/terms/"
  def ns(:cp), do: "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"

  def ns(:ep),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"

  def ns(:mc), do: "http://schemas.openxmlformats.org/markup-compatibility/2006"
  def ns(:xsi), do: "http://www.w3.org/2001/XMLSchema-instance"
  def ns(:p14), do: "http://schemas.microsoft.com/office/powerpoint/2010/main"

  @doc """
  Returns the relationship type URI for the given relationship key.

  Keys: `:office_document`, `:slide`, `:slide_layout`, `:slide_master`, `:theme`,
  `:pres_props`, `:view_props`, `:table_styles`, `:chart`, `:package`, `:image`,
  `:core_properties`, `:extended_properties`, `:thumbnail`, `:printer_settings`,
  `:hyperlink`, `:notes_slide`, `:notes_master`, `:video`, `:media`.
  """
  @spec rt(atom()) :: String.t()
  def rt(:office_document),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"

  def rt(:slide),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide"

  def rt(:slide_layout),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout"

  def rt(:slide_master),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster"

  def rt(:theme),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme"

  def rt(:pres_props),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/presProps"

  def rt(:view_props),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/viewProps"

  def rt(:table_styles),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/tableStyles"

  def rt(:chart),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/chart"

  def rt(:package),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/package"

  def rt(:image),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"

  def rt(:core_properties),
    do: "http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties"

  def rt(:extended_properties),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties"

  def rt(:thumbnail),
    do: "http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail"

  def rt(:printer_settings),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/printerSettings"

  def rt(:hyperlink),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"

  def rt(:notes_slide),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesSlide"

  def rt(:notes_master),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesMaster"

  def rt(:video),
    do: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/video"

  def rt(:media),
    do: "http://schemas.microsoft.com/office/2007/relationships/media"

  @doc """
  Returns the MIME content type string for the given content type key.

  Keys: `:presentation`, `:slide`, `:slide_layout`, `:slide_master`, `:theme`,
  `:pres_props`, `:view_props`, `:table_styles`, `:chart`, `:xlsx`,
  `:core_properties`, `:extended_properties`, `:xml`, `:rels`, `:jpeg`, `:png`,
  `:bmp`, `:gif`, `:tiff`, `:emf`, `:wmf`, `:printer_settings`, `:notes_slide`,
  `:notes_master`.
  """
  @spec ct(atom()) :: String.t()
  def ct(:presentation),
    do: "application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"

  def ct(:slide),
    do: "application/vnd.openxmlformats-officedocument.presentationml.slide+xml"

  def ct(:slide_layout),
    do: "application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"

  def ct(:slide_master),
    do: "application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"

  def ct(:theme),
    do: "application/vnd.openxmlformats-officedocument.theme+xml"

  def ct(:pres_props),
    do: "application/vnd.openxmlformats-officedocument.presentationml.presProps+xml"

  def ct(:view_props),
    do: "application/vnd.openxmlformats-officedocument.presentationml.viewProps+xml"

  def ct(:table_styles),
    do: "application/vnd.openxmlformats-officedocument.presentationml.tableStyles+xml"

  def ct(:chart),
    do: "application/vnd.openxmlformats-officedocument.drawingml.chart+xml"

  def ct(:xlsx),
    do: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  def ct(:core_properties),
    do: "application/vnd.openxmlformats-package.core-properties+xml"

  def ct(:extended_properties),
    do: "application/vnd.openxmlformats-officedocument.extended-properties+xml"

  def ct(:xml), do: "application/xml"
  def ct(:rels), do: "application/vnd.openxmlformats-package.relationships+xml"
  def ct(:jpeg), do: "image/jpeg"
  def ct(:png), do: "image/png"
  def ct(:bmp), do: "image/bmp"
  def ct(:gif), do: "image/gif"
  def ct(:tiff), do: "image/tiff"
  def ct(:emf), do: "image/x-emf"
  def ct(:wmf), do: "image/x-wmf"

  def ct(:printer_settings),
    do: "application/vnd.openxmlformats-officedocument.presentationml.printerSettings"

  def ct(:notes_slide),
    do: "application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml"

  def ct(:notes_master),
    do: "application/vnd.openxmlformats-officedocument.presentationml.notesMaster+xml"
end
