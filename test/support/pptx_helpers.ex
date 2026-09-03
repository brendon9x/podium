defmodule Podium.Test.PptxHelpers do
  @moduledoc false

  import ExUnit.Assertions

  @doc """
  Unzips a .pptx file (from path or binary) and returns a map of %{path => binary}.
  """
  def unzip_pptx(path) when is_binary(path) do
    {:ok, entries} = :zip.unzip(to_charlist(path), [:memory])
    Map.new(entries, fn {name, binary} -> {to_string(name), binary} end)
  end

  def unzip_pptx_binary(binary) when is_binary(binary) do
    {:ok, entries} = :zip.unzip(binary, [:memory])
    Map.new(entries, fn {name, binary} -> {to_string(name), binary} end)
  end

  @doc """
  Zips a directory of package parts into an in-memory pptx binary.

  Entry names are the paths relative to `dir`, so a directory laid out like an
  unzipped pptx becomes one.
  """
  def zip_dir(dir) when is_binary(dir) do
    entries =
      dir
      |> Path.join("**")
      |> Path.wildcard(match_dot: true)
      |> Enum.reject(&File.dir?/1)
      |> Enum.map(fn path ->
        {path |> Path.relative_to(dir) |> to_charlist(), File.read!(path)}
      end)

    {:ok, {_name, binary}} = :zip.create(~c"template.pptx", entries, [:memory])
    binary
  end

  @doc """
  Returns the list of file paths in a pptx parts map.
  """
  def file_list(parts) when is_map(parts) do
    Map.keys(parts) |> Enum.sort()
  end

  @doc """
  Asserts that every internal relationship target in a parts map resolves to a
  part that exists, so the package has no dangling relationships.
  """
  def assert_rels_resolve(parts) when is_map(parts) do
    for {rels_path, xml} <- parts, String.ends_with?(rels_path, ".rels") do
      owner_dir = rels_path |> Path.dirname() |> Path.dirname() |> strip_dot()

      for rel <- Podium.OPC.Relationships.parse(to_string(xml)).rels,
          tuple_size(rel) == 3 do
        target = elem(rel, 2)
        resolved = resolve_target(owner_dir, target)

        assert Map.has_key?(parts, resolved),
               "#{rels_path}: #{elem(rel, 0)} targets #{target}, " <>
                 "which resolves to #{resolved}, and no such part exists"
      end
    end

    :ok
  end

  defp strip_dot("."), do: ""
  defp strip_dot(dir), do: dir

  defp resolve_target(_owner_dir, "/" <> absolute), do: absolute

  defp resolve_target(owner_dir, target) do
    ["/", owner_dir, target] |> Path.join() |> Path.expand() |> String.trim_leading("/")
  end
end
