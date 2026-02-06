defmodule Podium.OPC.Package do
  @moduledoc false

  @doc """
  Reads a .pptx file and returns a map of %{path => binary}.
  """
  def read(path) do
    path = to_charlist(path)

    case :zip.unzip(path, [:memory]) do
      {:ok, entries} ->
        map =
          Map.new(entries, fn {name, binary} ->
            {to_string(name), binary}
          end)

        {:ok, map}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Reads the default.pptx template bundled with the library.
  """
  def read_template do
    template_path = Application.app_dir(:podium, "priv/templates/default.pptx")
    read(template_path)
  end

  @doc """
  Writes a map of %{path => binary} as a .pptx (ZIP) file.
  """
  def write(parts, output_path) when is_map(parts) do
    entries =
      Enum.map(parts, fn {name, binary} ->
        {to_charlist(name), binary}
      end)

    case :zip.create(to_charlist(output_path), entries) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Writes a map of parts to an in-memory ZIP binary.
  """
  def write_to_memory(parts) when is_map(parts) do
    entries =
      Enum.map(parts, fn {name, binary} ->
        {to_charlist(name), binary}
      end)

    case :zip.create(~c"output.pptx", entries, [:memory]) do
      {:ok, {_name, binary}} -> {:ok, binary}
      {:error, reason} -> {:error, reason}
    end
  end
end
