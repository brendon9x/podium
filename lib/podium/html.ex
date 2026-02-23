defmodule Podium.HTML do
  @moduledoc """
  Parses HTML strings into canonical paragraph maps for text rendering.

  This module provides an HTML text input layer so users can pass HTML strings
  anywhere text is accepted (`add_text_box`, table cells, `set_placeholder`,
  auto shapes) using the `{:html, string}` tagged tuple.

  ## Usage

      Podium.add_text_box(slide,
        {:html, ~s(<p><b>Bold</b> and <span style="color: #FF0000">red</span></p>)},
        x: {1, :inches}, y: {1, :inches}, width: {10, :inches}, height: {1, :inches})

  ## Supported elements

  ### Block elements
  - `<p>` — paragraph (with optional `style` for alignment)
  - `<br>` / `<br/>` — line break (flushes current runs into a paragraph)
  - `<ul>`, `<ol>` — unordered/ordered lists
  - `<li>` — list item (becomes a paragraph with bullet/number)

  ### Inline elements
  - `<b>`, `<strong>` — bold
  - `<i>`, `<em>` — italic
  - `<u>` — underline
  - `<s>`, `<del>` — strikethrough
  - `<sup>` — superscript
  - `<sub>` — subscript
  - `<span>` — inline container (with optional `style`)

  ### Style attributes
  Parsed from `style="..."` on `<span>` and `<p>` elements:
  - `color` — hex RGB (e.g., `color: #FF0000` or `color: #F00`)
  - `font-size` — in points (e.g., `font-size: 18pt`)
  - `font-family` — font name (e.g., `font-family: Arial`)
  - `text-align` — paragraph alignment (e.g., `text-align: center`)
  """

  @whitespace_pattern ~r/\s+/

  @doc """
  Parses an HTML string into canonical paragraph maps.

  Returns the same format as `Podium.Text.normalize/2` output — a list of
  paragraph maps with `:runs`, `:alignment`, `:line_spacing`, `:space_before`,
  `:space_after`, `:bullet`, and `:level` keys.

  ## Examples

      iex> Podium.HTML.parse("<b>Hello</b> world")
      [%{runs: [%{text: "Hello", opts: [bold: true]}, %{text: " world", opts: []}],
         alignment: nil, line_spacing: nil, space_before: nil, space_after: nil,
         bullet: nil, level: 0}]
  """
  @spec parse(String.t()) :: [map()]
  def parse(html) when is_binary(html) do
    {:ok, nodes} = Floki.parse_fragment(html)

    state = %{
      paragraphs: [],
      current_runs: [],
      current_para_opts: default_para_opts(),
      list_stack: []
    }

    state = walk_nodes(nodes, [], state)
    state = flush_paragraph(state)

    paragraphs = Enum.reverse(state.paragraphs)

    case paragraphs do
      [] -> [empty_paragraph()]
      paras -> paras
    end
  end

  # -- Node walking --

  defp walk_nodes([], _inline_opts, state), do: state

  defp walk_nodes([node | rest], inline_opts, state) do
    state = walk_node(node, inline_opts, state)
    walk_nodes(rest, inline_opts, state)
  end

  defp walk_node(text, inline_opts, state) when is_binary(text) do
    collapsed = collapse_whitespace(text)

    if collapsed == "" do
      state
    else
      run = %{text: collapsed, opts: inline_opts}
      %{state | current_runs: [run | state.current_runs]}
    end
  end

  defp walk_node({:comment, _}, _inline_opts, state), do: state

  defp walk_node({tag, attrs, children}, inline_opts, state) do
    tag = String.downcase(tag)

    cond do
      tag in ~w(p div) ->
        walk_block_element(tag, attrs, children, inline_opts, state)

      tag == "br" ->
        flush_paragraph(state)

      tag in ~w(ul ol) ->
        walk_list(tag, children, inline_opts, state)

      tag == "li" ->
        walk_list_item(attrs, children, inline_opts, state)

      tag in ~w(b strong i em u s del sup sub span) ->
        walk_inline_element(tag, attrs, children, inline_opts, state)

      true ->
        # Unknown tag — pass through children
        walk_nodes(children, inline_opts, state)
    end
  end

  # Block elements: <p>, <div>
  defp walk_block_element(_tag, attrs, children, inline_opts, state) do
    state = flush_paragraph(state)

    styles = parse_style_attr(attrs)
    alignment = parse_text_align(styles)

    para_opts =
      default_para_opts()
      |> maybe_put(:alignment, alignment)

    state = %{state | current_para_opts: para_opts}

    child_inline_opts = merge_inline_styles(inline_opts, styles)
    state = walk_nodes(children, child_inline_opts, state)
    flush_paragraph(state)
  end

  # Lists: <ul>, <ol>
  defp walk_list(tag, children, inline_opts, state) do
    list_type = if tag == "ol", do: :number, else: true
    state = %{state | list_stack: [list_type | state.list_stack]}
    state = walk_nodes(children, inline_opts, state)
    %{state | list_stack: tl(state.list_stack)}
  end

  # List items: <li>
  defp walk_list_item(_attrs, children, inline_opts, state) do
    state = flush_paragraph(state)

    level = max(length(state.list_stack) - 1, 0)
    bullet_type = List.first(state.list_stack, true)

    para_opts =
      default_para_opts()
      |> Map.put(:bullet, bullet_type)
      |> Map.put(:level, level)

    state = %{state | current_para_opts: para_opts}
    state = walk_nodes(children, inline_opts, state)
    flush_paragraph(state)
  end

  # Inline elements
  defp walk_inline_element(tag, attrs, children, inline_opts, state) do
    new_opts = inline_opts_for_tag(tag, attrs)
    merged = Keyword.merge(inline_opts, new_opts)
    walk_nodes(children, merged, state)
  end

  # -- Inline formatting --

  defp inline_opts_for_tag("b", _attrs), do: [bold: true]
  defp inline_opts_for_tag("strong", _attrs), do: [bold: true]
  defp inline_opts_for_tag("i", _attrs), do: [italic: true]
  defp inline_opts_for_tag("em", _attrs), do: [italic: true]
  defp inline_opts_for_tag("u", _attrs), do: [underline: true]
  defp inline_opts_for_tag("s", _attrs), do: [strikethrough: true]
  defp inline_opts_for_tag("del", _attrs), do: [strikethrough: true]
  defp inline_opts_for_tag("sup", _attrs), do: [superscript: true]
  defp inline_opts_for_tag("sub", _attrs), do: [subscript: true]

  defp inline_opts_for_tag("span", attrs) do
    styles = parse_style_attr(attrs)
    inline_opts_from_styles(styles)
  end

  defp inline_opts_from_styles(styles) do
    [
      color: styles |> Map.get("color") |> normalize_color(),
      font_size: styles |> Map.get("font-size") |> parse_font_size(),
      font: styles |> Map.get("font-family") |> clean_font_name()
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp merge_inline_styles(inline_opts, styles) do
    style_opts = inline_opts_from_styles(styles)
    Keyword.merge(inline_opts, style_opts)
  end

  # -- Style parsing --

  defp parse_style_attr(attrs) do
    case List.keyfind(attrs, "style", 0) do
      {"style", style_string} -> parse_css_properties(style_string)
      nil -> %{}
    end
  end

  defp parse_css_properties(style_string) do
    style_string
    |> String.split(";")
    |> Enum.reduce(%{}, fn declaration, acc ->
      case String.split(declaration, ":", parts: 2) do
        [property, value] ->
          Map.put(acc, String.trim(property), String.trim(value))

        _ ->
          acc
      end
    end)
  end

  defp parse_text_align(styles) do
    case Map.get(styles, "text-align") do
      "left" -> :left
      "center" -> :center
      "right" -> :right
      "justify" -> :justify
      _ -> nil
    end
  end

  defp normalize_color(nil), do: nil

  defp normalize_color(color) do
    color = String.trim(color)

    cond do
      String.starts_with?(color, "#") && byte_size(color) == 7 ->
        String.slice(color, 1..-1//1)

      String.starts_with?(color, "#") && byte_size(color) == 4 ->
        # Expand shorthand #RGB to RRGGBB
        <<_hash, r, g, b>> = color
        <<r, r, g, g, b, b>>

      true ->
        color
    end
  end

  defp parse_font_size(nil), do: nil

  defp parse_font_size(size) do
    size = String.trim(size)

    cond do
      String.ends_with?(size, "pt") ->
        size |> String.trim_trailing("pt") |> String.trim() |> parse_number()

      String.ends_with?(size, "px") ->
        # Approximate px to pt (1px ≈ 0.75pt)
        case size |> String.trim_trailing("px") |> String.trim() |> parse_number() do
          nil -> nil
          n -> n * 0.75
        end

      true ->
        parse_number(size)
    end
  end

  defp parse_number(str) do
    case Float.parse(str) do
      {n, _} -> if n == trunc(n), do: trunc(n), else: n
      :error -> nil
    end
  end

  defp clean_font_name(nil), do: nil

  defp clean_font_name(font) do
    font
    |> String.split(",")
    |> List.first("")
    |> String.trim()
    |> String.trim("'")
    |> String.trim("\"")
  end

  # -- Paragraph management --

  defp flush_paragraph(%{current_runs: []} = state) do
    %{state | current_para_opts: default_para_opts()}
  end

  defp flush_paragraph(state) do
    # Reverse accumulated runs (prepended during walk), then trim whitespace
    runs =
      state.current_runs
      |> Enum.reverse()
      |> trim_runs()

    if runs == [] do
      %{state | current_runs: [], current_para_opts: default_para_opts()}
    else
      para = Map.put(state.current_para_opts, :runs, runs)

      %{
        state
        | paragraphs: [para | state.paragraphs],
          current_runs: [],
          current_para_opts: default_para_opts()
      }
    end
  end

  defp trim_runs([]), do: []

  defp trim_runs(runs) do
    runs
    |> trim_run_start()
    |> trim_run_end()
  end

  defp trim_run_start([%{text: text} = run | rest]) do
    trimmed = String.trim_leading(text)

    if trimmed == "" do
      trim_run_start(rest)
    else
      [%{run | text: trimmed} | rest]
    end
  end

  defp trim_run_start([]), do: []

  defp trim_run_end([]), do: []

  defp trim_run_end(runs) do
    runs
    |> Enum.reverse()
    |> trim_from_head_trailing()
    |> Enum.reverse()
  end

  defp trim_from_head_trailing([%{text: text} = run | rest]) do
    trimmed = String.trim_trailing(text)

    if trimmed == "" do
      trim_from_head_trailing(rest)
    else
      [%{run | text: trimmed} | rest]
    end
  end

  defp trim_from_head_trailing([]), do: []

  # -- Whitespace --

  defp collapse_whitespace(text) do
    String.replace(text, @whitespace_pattern, " ")
  end

  # -- Defaults --

  defp default_para_opts do
    %{
      alignment: nil,
      line_spacing: nil,
      space_before: nil,
      space_after: nil,
      bullet: nil,
      level: 0
    }
  end

  defp empty_paragraph do
    %{
      runs: [%{text: "", opts: []}],
      alignment: nil,
      line_spacing: nil,
      space_before: nil,
      space_after: nil,
      bullet: nil,
      level: 0
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
