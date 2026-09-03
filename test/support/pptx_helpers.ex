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
      owner_partname = owner_partname(rels_path)

      for rel <- Podium.OPC.Relationships.parse(to_string(xml)).rels,
          tuple_size(rel) == 3 do
        target = elem(rel, 2)
        resolved = Podium.OPC.Package.resolve_partname(owner_partname, target)

        assert Map.has_key?(parts, resolved),
               "#{rels_path}: #{elem(rel, 0)} targets #{target}, " <>
                 "which resolves to #{resolved}, and no such part exists"
      end
    end

    :ok
  end

  # "ppt/_rels/presentation.xml.rels" describes "ppt/presentation.xml", and the
  # package-level "_rels/.rels" describes the package root.
  defp owner_partname(rels_path) do
    dir = rels_path |> Path.dirname() |> Path.dirname()
    base = rels_path |> Path.basename() |> String.replace_suffix(".rels", "")

    if dir in [".", ""], do: base, else: Path.join(dir, base)
  end
end
