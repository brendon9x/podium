defmodule Podium.OPC.PackageTest do
  use ExUnit.Case, async: true

  alias Podium.OPC.Package

  @template_path "priv/templates/default.pptx"

  describe "read/1" do
    test "reads a pptx file into a map of parts" do
      {:ok, parts} = Package.read(@template_path)

      assert is_map(parts)
      assert Map.has_key?(parts, "[Content_Types].xml")
      assert Map.has_key?(parts, "_rels/.rels")
      assert Map.has_key?(parts, "ppt/presentation.xml")
      assert Map.has_key?(parts, "ppt/slideMasters/slideMaster1.xml")
    end

    test "returns error for non-existent file" do
      assert {:error, _} = Package.read("nonexistent.pptx")
    end
  end

  describe "round-trip" do
    test "unzip and rezip produces a valid pptx" do
      {:ok, original_parts} = Package.read(@template_path)

      # Write to a temp file
      tmp_path = Path.join(System.tmp_dir!(), "podium_roundtrip_test.pptx")

      on_exit(fn -> File.rm(tmp_path) end)

      assert :ok = Package.write(original_parts, tmp_path)

      # Read back and verify same parts
      {:ok, roundtrip_parts} = Package.read(tmp_path)

      assert Map.keys(original_parts) |> Enum.sort() ==
               Map.keys(roundtrip_parts) |> Enum.sort()

      # Verify content is preserved
      for {path, content} <- original_parts do
        assert roundtrip_parts[path] == content,
               "Content mismatch for #{path}"
      end
    end

    test "write_to_memory produces valid zip binary" do
      {:ok, parts} = Package.read(@template_path)
      {:ok, binary} = Package.write_to_memory(parts)

      # Verify we can unzip the binary
      {:ok, entries} = :zip.unzip(binary, [:memory])
      roundtrip_parts = Map.new(entries, fn {name, bin} -> {to_string(name), bin} end)

      assert Map.keys(parts) |> Enum.sort() ==
               Map.keys(roundtrip_parts) |> Enum.sort()
    end
  end
end
