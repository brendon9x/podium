defmodule Podium.OPC.Package do
  @moduledoc """
  OPC (Open Packaging Convention) ZIP package read/write operations.

  Reads and writes `.pptx` files as ZIP archives containing XML parts and
  binary resources. Each part is represented as a `%{path => binary}` map.
  """

  @doc """
  Reads a .pptx file and returns a map of %{path => binary}.
  """
  @spec read(String.t()) :: {:ok, %{String.t() => binary()}} | {:error, term()}
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
  @spec read_template() :: {:ok, %{String.t() => binary()}} | {:error, term()}
  def read_template do
    template_path = Application.app_dir(:podium, "priv/templates/default.pptx")
    read(template_path)
  end

  @doc """
  Writes a map of %{path => binary} as a .pptx (ZIP) file.
  """
  @spec write(%{String.t() => binary()}, String.t()) :: :ok | {:error, term()}
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
  @spec write_to_memory(%{String.t() => binary()}) :: {:ok, binary()} | {:error, term()}
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
