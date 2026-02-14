defmodule Podium.OPC.Relationships do
  @moduledoc """
  `.rels` file management for OPC relationship parts.

  Manages a collection of relationships (each with an ID, type URI, and target
  path) and renders them to the XML used in `.rels` files throughout the package.
  """

  alias Podium.OPC.Constants

  defstruct rels: [], next_id: 1

  @type t :: %__MODULE__{
          rels: [tuple()],
          next_id: pos_integer()
        }

  @doc """
  Creates a new empty relationships collection.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates relationships from an existing list, setting next_id appropriately.
  """
  @spec from_list([tuple()]) :: t()
  def from_list(rels) when is_list(rels) do
    max_id =
      rels
      |> Enum.map(fn
        {id, _type, _target} ->
          id |> String.replace_prefix("rId", "") |> String.to_integer()

        {id, _type, _target, _external} ->
          id |> String.replace_prefix("rId", "") |> String.to_integer()
      end)
      |> Enum.max(fn -> 0 end)

    %__MODULE__{rels: rels, next_id: max_id + 1}
  end

  @doc """
  Adds a relationship and returns {updated_rels, rId}.
  """
  @spec add(t(), String.t(), String.t(), boolean()) :: {t(), String.t()}
  def add(%__MODULE__{} = rels, type, target, external \\ false) do
    rid = "rId#{rels.next_id}"
    new_rel = if external, do: {rid, type, target, true}, else: {rid, type, target}

    {%{rels | rels: rels.rels ++ [new_rel], next_id: rels.next_id + 1}, rid}
  end

  @doc """
  Generates the .rels XML string.
  """
  @spec to_xml(t()) :: String.t()
  def to_xml(%__MODULE__{} = rels) do
    rels_xml =
      rels.rels
      |> Enum.map(fn
        {id, type, target, true} ->
          ~s(<Relationship Id="#{id}" Type="#{type}" Target="#{target}" TargetMode="External"/>)

        {id, type, target} ->
          ~s(<Relationship Id="#{id}" Type="#{type}" Target="#{target}"/>)
      end)
      |> Enum.join()

    ns = Constants.ns(:pr)

    Podium.XML.Builder.xml_declaration() <>
      ~s(<Relationships xmlns="#{ns}">#{rels_xml}</Relationships>)
  end
end
