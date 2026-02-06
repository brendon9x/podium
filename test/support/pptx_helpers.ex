defmodule Podium.Test.PptxHelpers do
  @moduledoc false

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
  Returns the list of file paths in a pptx parts map.
  """
  def file_list(parts) when is_map(parts) do
    Map.keys(parts) |> Enum.sort()
  end
end
