defmodule Podium.OPC.ContentTypes do
  @moduledoc false

  alias Podium.OPC.Constants

  @doc """
  Builds a content types struct from existing defaults/overrides and a list of parts to add.
  """
  defstruct defaults: %{}, overrides: %{}

  @doc """
  Returns the base content types from the default template.
  """
  def from_template do
    %__MODULE__{
      defaults: %{
        "xml" => Constants.ct(:xml),
        "jpeg" => Constants.ct(:jpeg),
        "bin" => Constants.ct(:printer_settings),
        "rels" => Constants.ct(:rels)
      },
      overrides: %{
        "/ppt/presentation.xml" => Constants.ct(:presentation),
        "/ppt/slideMasters/slideMaster1.xml" => Constants.ct(:slide_master),
        "/ppt/presProps.xml" => Constants.ct(:pres_props),
        "/ppt/viewProps.xml" => Constants.ct(:view_props),
        "/ppt/theme/theme1.xml" => Constants.ct(:theme),
        "/ppt/tableStyles.xml" => Constants.ct(:table_styles),
        "/ppt/slideLayouts/slideLayout1.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout2.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout3.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout4.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout5.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout6.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout7.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout8.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout9.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout10.xml" => Constants.ct(:slide_layout),
        "/ppt/slideLayouts/slideLayout11.xml" => Constants.ct(:slide_layout),
        "/docProps/core.xml" => Constants.ct(:core_properties),
        "/docProps/app.xml" => Constants.ct(:extended_properties)
      }
    }
  end

  @doc """
  Adds an override content type for a specific part.
  """
  def add_override(%__MODULE__{} = ct, part_name, content_type) do
    %{ct | overrides: Map.put(ct.overrides, part_name, content_type)}
  end

  @doc """
  Adds a default content type for a file extension.
  """
  def add_default(%__MODULE__{} = ct, extension, content_type) do
    %{ct | defaults: Map.put(ct.defaults, extension, content_type)}
  end

  @doc """
  Generates the [Content_Types].xml string.
  """
  def to_xml(%__MODULE__{} = ct) do
    defaults_xml =
      ct.defaults
      |> Enum.sort()
      |> Enum.map(fn {ext, content_type} ->
        ~s(<Default Extension="#{ext}" ContentType="#{content_type}"/>)
      end)
      |> Enum.join()

    overrides_xml =
      ct.overrides
      |> Enum.sort()
      |> Enum.map(fn {part_name, content_type} ->
        ~s(<Override PartName="#{part_name}" ContentType="#{content_type}"/>)
      end)
      |> Enum.join()

    ns = Constants.ns(:ct)

    Podium.XML.Builder.xml_declaration() <>
      ~s(<Types xmlns="#{ns}">#{defaults_xml}#{overrides_xml}</Types>)
  end
end
