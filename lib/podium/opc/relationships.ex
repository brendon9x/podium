defmodule Podium.OPC.Relationships do
  @moduledoc """
  `.rels` file management for OPC relationship parts.

  Manages a collection of relationships (each with an ID, type URI, and target
  path) and renders them to the XML used in `.rels` files throughout the package.
  """

  alias Podium.OPC.Constants

  defstruct rels: [], next_id: 1

  @type rel ::
          {String.t(), String.t(), String.t()}
          | {String.t(), String.t(), String.t(), true}

  @type t :: %__MODULE__{
          rels: [rel()],
          next_id: pos_integer()
        }

  @doc """
  Creates a new empty relationships collection.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates relationships from an existing list, setting next_id appropriately.

  Only ids of the form `rIdN` contribute to `next_id`; any other id is kept but
  ignored when picking the next one, so foreign ids never cause a collision.
  """
  @spec from_list([rel()]) :: t()
  def from_list(rels) when is_list(rels) do
    max_id =
      rels
      |> Enum.flat_map(fn rel ->
        case Regex.run(~r/^rId(\d+)$/, elem(rel, 0)) do
          [_, digits] -> [String.to_integer(digits)]
          nil -> []
        end
      end)
      |> Enum.max(fn -> 0 end)

    %__MODULE__{rels: rels, next_id: max_id + 1}
  end

  @relationship_re ~r/<Relationship\s[^>]*\/?>/

  @doc """
  Parses a `.rels` XML string into a `%Relationships{}`.

  Each relationship becomes `{id, type, target}`, or `{id, type, target, true}`
  when `TargetMode="External"`. Attribute order in the source does not matter.
  """
  @spec parse(String.t()) :: t()
  def parse(xml) when is_binary(xml) do
    @relationship_re
    |> Regex.scan(xml)
    |> Enum.flat_map(fn [element] ->
      with id when is_binary(id) <- attribute(element, "Id"),
           type when is_binary(type) <- attribute(element, "Type"),
           target when is_binary(target) <- attribute(element, "Target") do
        if attribute(element, "TargetMode") == "External" do
          [{id, type, target, true}]
        else
          [{id, type, target}]
        end
      else
        _ -> []
      end
    end)
    |> from_list()
  end

  @doc """
  Returns `{rid, target}` for the first relationship of the given type, or `nil`.
  """
  @spec find_by_type(t(), String.t()) :: {String.t(), String.t()} | nil
  def find_by_type(%__MODULE__{} = rels, type) do
    Enum.find_value(rels.rels, fn rel ->
      if elem(rel, 1) == type, do: {elem(rel, 0), elem(rel, 2)}
    end)
  end

  defp attribute(element, name) do
    case Regex.run(~r/\s#{name}="([^"]*)"/, element) do
      [_, value] -> value
      nil -> nil
    end
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
