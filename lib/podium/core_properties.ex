defmodule Podium.CoreProperties do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.XML.Builder

  defstruct [
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

  @doc """
  Creates a CoreProperties struct from a keyword list.
  """
  def new(opts \\ []) do
    %__MODULE__{
      title: Keyword.get(opts, :title),
      author: Keyword.get(opts, :author),
      subject: Keyword.get(opts, :subject),
      keywords: Keyword.get(opts, :keywords),
      category: Keyword.get(opts, :category),
      comments: Keyword.get(opts, :comments),
      last_modified_by: Keyword.get(opts, :last_modified_by),
      created: Keyword.get(opts, :created),
      modified: Keyword.get(opts, :modified),
      last_printed: Keyword.get(opts, :last_printed),
      revision: Keyword.get(opts, :revision),
      content_status: Keyword.get(opts, :content_status),
      language: Keyword.get(opts, :language),
      version: Keyword.get(opts, :version)
    }
  end

  @doc """
  Generates the Dublin Core XML for docProps/core.xml.
  """
  def to_xml(%__MODULE__{} = props) do
    children =
      [
        element("dc:title", props.title),
        element("dc:creator", props.author),
        element("dc:subject", props.subject),
        element("cp:keywords", props.keywords),
        element("cp:category", props.category),
        element("dc:description", props.comments),
        element("cp:lastModifiedBy", props.last_modified_by),
        datetime_element("dcterms:created", props.created),
        datetime_element("dcterms:modified", props.modified),
        simple_datetime_element("cp:lastPrinted", props.last_printed),
        integer_element("cp:revision", props.revision),
        element("cp:contentStatus", props.content_status),
        element("dc:language", props.language),
        element("cp:version", props.version)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join()

    has_datetime = props.created || props.modified || props.last_printed
    xsi_ns = if has_datetime, do: ~s( xmlns:xsi="#{Constants.ns(:xsi)}"), else: ""

    Builder.xml_declaration() <>
      ~s(<cp:coreProperties) <>
      ~s( xmlns:cp="#{Constants.ns(:cp)}") <>
      ~s( xmlns:dc="#{Constants.ns(:dc)}") <>
      ~s( xmlns:dcterms="#{Constants.ns(:dcterms)}"#{xsi_ns}>) <>
      children <>
      ~s(</cp:coreProperties>)
  end

  defp element(_tag, nil), do: nil
  defp element(tag, value), do: "<#{tag}>#{Builder.escape(value)}</#{tag}>"

  defp datetime_element(_tag, nil), do: nil

  defp datetime_element(tag, %DateTime{} = dt) do
    formatted = Calendar.strftime(dt, "%Y-%m-%dT%H:%M:%SZ")
    ~s(<#{tag} xsi:type="dcterms:W3CDTF">#{formatted}</#{tag}>)
  end

  defp simple_datetime_element(_tag, nil), do: nil

  defp simple_datetime_element(tag, %DateTime{} = dt) do
    formatted = Calendar.strftime(dt, "%Y-%m-%dT%H:%M:%SZ")
    "<#{tag}>#{formatted}</#{tag}>"
  end

  defp integer_element(_tag, nil), do: nil
  defp integer_element(tag, value) when is_integer(value), do: "<#{tag}>#{value}</#{tag}>"
end
