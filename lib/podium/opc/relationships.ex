defmodule Podium.OPC.Relationships do
  @moduledoc false

  alias Podium.OPC.Constants

  defstruct rels: [], next_id: 1

  @doc """
  Creates a new empty relationships collection.
  """
  def new, do: %__MODULE__{}

  @doc """
  Creates relationships from an existing list, setting next_id appropriately.
  """
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
  def add(%__MODULE__{} = rels, type, target, external \\ false) do
    rid = "rId#{rels.next_id}"
    new_rel = if external, do: {rid, type, target, true}, else: {rid, type, target}

    {%{rels | rels: rels.rels ++ [new_rel], next_id: rels.next_id + 1}, rid}
  end

  @doc """
  Generates the .rels XML string.
  """
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
