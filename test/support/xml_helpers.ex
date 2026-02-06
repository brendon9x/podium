defmodule Podium.Test.XmlHelpers do
  @moduledoc false
  import SweetXml, only: [sigil_x: 2]

  @doc """
  Parses XML and returns the value at the given XPath.
  """
  def xpath_text(xml, path) do
    xml |> SweetXml.parse(namespace_conformant: true) |> SweetXml.xpath(~x"#{path}"s)
  end

  @doc """
  Parses XML and returns a list of values at the given XPath.
  """
  def xpath_list(xml, path) do
    xml |> SweetXml.parse(namespace_conformant: true) |> SweetXml.xpath(~x"#{path}"ls)
  end

  @doc """
  Returns the number of nodes matching the given XPath.
  """
  def xpath_count(xml, path) do
    xml |> SweetXml.parse(namespace_conformant: true) |> SweetXml.xpath(~x"#{path}"l) |> length()
  end
end
