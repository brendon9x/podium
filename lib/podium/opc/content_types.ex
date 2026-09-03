defmodule Podium.OPC.ContentTypes do
  @moduledoc """
  `[Content_Types].xml` management for the OPC package.

  Tracks default content types (by file extension) and override content types
  (by part name) and renders them to the XML expected at the package root.
  """

  alias Podium.OPC.Constants

  defstruct defaults: %{}, overrides: %{}

  @type t :: %__MODULE__{
          defaults: %{String.t() => String.t()},
          overrides: %{String.t() => String.t()}
        }

  @default_re ~r/<Default\s[^>]*\/?>/
  @override_re ~r/<Override\s[^>]*\/?>/

  @doc """
  Parses a `[Content_Types].xml` string into a `%ContentTypes{}`.

  Attributes are matched individually so their order in the source does not
  matter. `Extension` values are downcased because OPC extension matching is
  case-insensitive.
  """
  def parse(xml) when is_binary(xml) do
    defaults =
      @default_re
      |> Regex.scan(xml)
      |> Enum.flat_map(fn [element] ->
        with ext when is_binary(ext) <- attribute(element, "Extension"),
             ct when is_binary(ct) <- attribute(element, "ContentType") do
          [{String.downcase(ext), ct}]
        else
          _ -> []
        end
      end)
      |> Map.new()

    overrides =
      @override_re
      |> Regex.scan(xml)
      |> Enum.flat_map(fn [element] ->
        with part when is_binary(part) <- attribute(element, "PartName"),
             ct when is_binary(ct) <- attribute(element, "ContentType") do
          [{part, ct}]
        else
          _ -> []
        end
      end)
      |> Map.new()

    %__MODULE__{defaults: defaults, overrides: overrides}
  end

  defp attribute(element, name) do
    case Regex.run(~r/\s#{name}="([^"]*)"/, element) do
      [_, value] -> value
      nil -> nil
    end
  end

  @doc """
  Adds an override content type for a specific part.
  """
  @spec add_override(t(), String.t(), String.t()) :: t()
  def add_override(%__MODULE__{} = ct, part_name, content_type) do
    %{ct | overrides: Map.put(ct.overrides, part_name, content_type)}
  end

  @doc """
  Adds a default content type for a file extension.

  Extensions are downcased so a template declaring `Extension="PNG"` and a part
  added as `"png"` do not produce two conflicting `Default` entries.
  """
  @spec add_default(t(), String.t(), String.t()) :: t()
  def add_default(%__MODULE__{} = ct, extension, content_type) do
    %{ct | defaults: Map.put(ct.defaults, String.downcase(extension), content_type)}
  end

  @doc """
  Generates the [Content_Types].xml string.
  """
  @spec to_xml(t()) :: String.t()
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
