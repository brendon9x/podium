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
    :last_modified_by
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
      last_modified_by: Keyword.get(opts, :last_modified_by)
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
        element("cp:lastModifiedBy", props.last_modified_by)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join()

    Builder.xml_declaration() <>
      ~s(<cp:coreProperties) <>
      ~s( xmlns:cp="#{Constants.ns(:cp)}") <>
      ~s( xmlns:dc="#{Constants.ns(:dc)}") <>
      ~s( xmlns:dcterms="#{Constants.ns(:dcterms)}">) <>
      children <>
      ~s(</cp:coreProperties>)
  end

  defp element(_tag, nil), do: nil
  defp element(tag, value), do: "<#{tag}>#{Builder.escape(value)}</#{tag}>"
end
