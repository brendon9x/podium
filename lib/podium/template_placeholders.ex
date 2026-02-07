defmodule Podium.TemplatePlaceholders do
  @moduledoc false

  alias Podium.Placeholder

  @doc """
  Parses template layout and master XMLs to extract placeholder positions.

  Returns a map of `%{layout_index => %{placeholder_name => %{x, y, cx, cy}}}` where
  only content placeholders (type: nil) are included — these are the ones that can
  accept charts and tables.
  """
  def resolve_positions(template_parts) do
    master_positions = parse_master_positions(template_parts)

    for layout_index <- 1..11, into: %{} do
      layout_key = "ppt/slideLayouts/slideLayout#{layout_index}.xml"
      layout_xml = to_string(Map.get(template_parts, layout_key, ""))
      layout_atom = layout_atom(layout_index)
      content_phs = content_placeholders_for(layout_atom)

      positions =
        for {name, %{idx: idx}} <- content_phs, into: %{} do
          pos =
            parse_layout_placeholder_position(layout_xml, idx) ||
              master_fallback(master_positions)

          {name, pos}
        end

      # Only include layouts that have content placeholders with resolved positions
      positions = Map.filter(positions, fn {_k, v} -> v != nil end)
      {layout_index, positions}
    end
    |> Map.filter(fn {_k, v} -> v != %{} end)
  end

  # Extract positions from the slide master for fallback
  defp parse_master_positions(template_parts) do
    master_xml = to_string(Map.get(template_parts, "ppt/slideMasters/slideMaster1.xml", ""))
    parse_sp_blocks(master_xml)
  end

  # Parse all <p:sp> blocks from XML and return a list of {type, idx, position} tuples
  defp parse_sp_blocks(xml) do
    # Extract all <p:sp>...</p:sp> blocks
    ~r/<p:sp>(.+?)<\/p:sp>/s
    |> Regex.scan(xml)
    |> Enum.map(fn [_full, body] ->
      {parse_ph(body), parse_position(body)}
    end)
    |> Enum.filter(fn {{type, _idx}, pos} -> type != nil and pos != nil end)
    |> Map.new(fn {{type, idx}, pos} -> {{type, idx}, pos} end)
  end

  # Parse <p:ph type="..." idx="..."/> from a shape block
  defp parse_ph(block) do
    type =
      case Regex.run(~r/<p:ph[^>]*\stype="([^"]*)"/, block) do
        [_, t] -> t
        nil -> nil
      end

    idx =
      case Regex.run(~r/<p:ph[^>]*\sidx="(\d+)"/, block) do
        [_, i] -> String.to_integer(i)
        nil -> nil
      end

    {type, idx}
  end

  # Parse position from <a:xfrm> containing <a:off> and <a:ext>
  defp parse_position(block) do
    with [_, x] <- Regex.run(~r/<a:off\s[^>]*x="(\d+)"/, block),
         [_, y] <- Regex.run(~r/<a:off\s[^>]*y="(\d+)"/, block),
         [_, cx] <- Regex.run(~r/<a:ext\s[^>]*cx="(\d+)"/, block),
         [_, cy] <- Regex.run(~r/<a:ext\s[^>]*cy="(\d+)"/, block) do
      %{
        x: String.to_integer(x),
        y: String.to_integer(y),
        cx: String.to_integer(cx),
        cy: String.to_integer(cy)
      }
    else
      _ -> nil
    end
  end

  # Parse a specific placeholder position from layout XML by idx
  # Content placeholders have no type attribute, just idx
  defp parse_layout_placeholder_position(layout_xml, idx) do
    ~r/<p:sp>(.+?)<\/p:sp>/s
    |> Regex.scan(layout_xml)
    |> Enum.find_value(fn [_full, body] ->
      {type, parsed_idx} = parse_ph(body)

      if type == nil and parsed_idx == idx do
        parse_position(body)
      end
    end)
  end

  # Fallback to master's body placeholder position (type="body", idx="1")
  defp master_fallback(master_positions) do
    Map.get(master_positions, {"body", 1})
  end

  # Return only content placeholders (type: nil) for a layout
  defp content_placeholders_for(layout_atom) do
    layout_atom
    |> Placeholder.placeholders_for()
    |> Enum.filter(fn {_name, %{type: type}} -> type == nil end)
    |> Map.new()
  end

  defp layout_atom(1), do: :title_slide
  defp layout_atom(2), do: :title_content
  defp layout_atom(3), do: :section_header
  defp layout_atom(4), do: :two_content
  defp layout_atom(5), do: :comparison
  defp layout_atom(6), do: :title_only
  defp layout_atom(7), do: :blank
  defp layout_atom(8), do: :content_caption
  defp layout_atom(9), do: :picture_caption
  defp layout_atom(10), do: :title_vertical_text
  defp layout_atom(11), do: :vertical_title_text
end
