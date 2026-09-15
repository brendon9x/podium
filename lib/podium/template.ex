defmodule Podium.Template do
  @moduledoc """
  Read-only structural inspection of a template package.

  `inspect/1` reads a `.pptx`/`.potx` package and reports what is actually in
  it: the slide size, the slide masters, and for every slide layout its name,
  its type, the master it sits on, and every placeholder it defines with the
  bounding box that placeholder resolves to.

      template = Podium.Template.inspect("priv/brand/skeleton.pptx")

      for {index, layout} <- Enum.sort(template.layouts) do
        IO.puts("\#{index}: \#{layout.name}")

        for ph <- layout.placeholders do
          IO.puts("   {\#{ph.type}, \#{ph.idx}} \#{ph.name}")
        end
      end

  The `{type, idx}` pair reported for a placeholder is what
  `Podium.set_placeholder/3`, `Podium.set_picture_placeholder/3`,
  `Podium.set_chart_placeholder/6` and `Podium.set_table_placeholder/5` take to
  address that placeholder on a slide built on the layout.

  ## Placeholder attribute defaults

  A `<p:ph/>` element without a `type` attribute means `"obj"`, and one without
  an `idx` attribute means `0`. Inspection fills both in, so a placeholder's
  `type` is always a string and its `idx` always an integer.

  ## Box inheritance

  A layout placeholder that carries its own `<a:xfrm>` uses it. One that does
  not inherits the box of the master placeholder found **by type**: `ctrTitle`
  and `title` inherit from the master's `title`; `body`, `subTitle`, `obj`,
  `chart`, `tbl`, `pic`, `clipArt`, `dgm` and `media` inherit from the master's
  `body`; `dt`, `ftr` and `sldNum` inherit from the master placeholder of the
  same type. This is how PowerPoint resolves it. `box` is `nil` when nothing in
  the chain has a position.
  """

  import Kernel, except: [inspect: 1]

  alias Podium.OPC.{Constants, Package, PresentationXml, Relationships}
  alias Podium.Placeholder

  defstruct slide_size: {9_144_000, 6_858_000}, masters: %{}, layouts: %{}

  @type box :: %{x: integer(), y: integer(), w: integer(), h: integer()}

  @type placeholder :: %{
          type: String.t(),
          idx: non_neg_integer(),
          name: String.t() | nil,
          box: box() | nil
        }

  @type layout :: %{
          index: pos_integer(),
          name: String.t() | nil,
          type: String.t() | nil,
          master_index: pos_integer() | nil,
          placeholders: [placeholder()]
        }

  @type t :: %__MODULE__{
          slide_size: {non_neg_integer(), non_neg_integer()},
          masters: %{pos_integer() => %{placeholders: [placeholder()]}},
          layouts: %{pos_integer() => layout()}
        }

  @typedoc """
  A way of naming one placeholder on a layout: the `{type, idx}` pair
  inspection reports, a `%Podium.Placeholder{}`, or any map carrying `:type`
  and `:idx`. A `nil` type means `"obj"` and a `nil` idx means `0`.
  """
  @type ref ::
          {String.t() | nil, non_neg_integer() | nil}
          | %{
              :type => String.t() | nil,
              :idx => non_neg_integer() | nil,
              optional(atom()) => term()
            }

  @default_slide_size {9_144_000, 6_858_000}

  @doc """
  Inspects a template package and returns a `%Podium.Template{}`.

  `source` is a parts map (`%{partname => binary}`), a path to a
  `.pptx`/`.potx` file, or the bytes of one.
  """
  @spec inspect(%{String.t() => binary()} | binary()) :: t()
  def inspect(parts) when is_map(parts) and not is_struct(parts), do: from_parts(parts)

  def inspect(source) when is_binary(source) do
    case Package.read_source(source) do
      {:ok, parts} ->
        from_parts(parts)

      {:error, reason} ->
        raise ArgumentError, "could not read template package: #{Kernel.inspect(reason)}"
    end
  end

  @doc """
  The inspection of the template bundled with Podium, cached in
  `:persistent_term` because its parts never change.
  """
  @spec bundled() :: t()
  def bundled do
    key = {__MODULE__, :bundled}

    case :persistent_term.get(key, nil) do
      nil ->
        {:ok, parts} = Package.read_default_template()
        template = from_parts(parts)
        :persistent_term.put(key, template)
        template

      cached ->
        cached
    end
  end

  @doc """
  The placeholder on `layout_index` addressed by `{type, idx}`, or `nil` when
  the layout has no placeholder with that idx or its type is a different one.

  A `nil` type in the reference means `"obj"` and a `nil` idx means `0`, so a
  definition taken from `Podium.Placeholder.placeholders_for/1` can be passed
  straight in.
  """
  @spec placeholder(t(), pos_integer(), ref()) :: placeholder() | nil
  def placeholder(%__MODULE__{} = template, layout_index, ref) do
    {type, idx} = Placeholder.normalize_ref(ref)

    case placeholder_by_idx(template, layout_index, idx) do
      %{type: ^type} = ph -> ph
      _ -> nil
    end
  end

  @doc """
  The placeholder on `layout_index` with the given idx whatever its type, or
  `nil`. Callers that need to tell "no such idx" apart from "wrong type" use
  this rather than `placeholder/3`.
  """
  @spec placeholder_by_idx(t(), pos_integer(), non_neg_integer()) :: placeholder() | nil
  def placeholder_by_idx(%__MODULE__{} = template, layout_index, idx) when is_integer(idx) do
    template
    |> layout_placeholders(layout_index)
    |> Enum.find(&(&1.idx == idx))
  end

  @doc """
  The first placeholder of the given type on `layout_index`, or `nil`. Used to
  find the layout's footer, date and slide number chrome.
  """
  @spec placeholder_by_type(t(), pos_integer(), String.t()) :: placeholder() | nil
  def placeholder_by_type(%__MODULE__{} = template, layout_index, type) when is_binary(type) do
    template
    |> layout_placeholders(layout_index)
    |> Enum.find(&(&1.type == type))
  end

  defp layout_placeholders(template, layout_index) do
    case Map.get(template.layouts, layout_index) do
      nil -> []
      layout -> layout.placeholders
    end
  end

  # --- Inspection ---

  defp from_parts(parts) do
    slide_size =
      case Map.get(parts, "ppt/presentation.xml") do
        nil -> @default_slide_size
        xml -> PresentationXml.slide_size(to_string(xml)) || @default_slide_size
      end

    masters = parse_masters(parts)

    %__MODULE__{
      slide_size: slide_size,
      masters: masters,
      layouts: parse_layouts(parts, masters)
    }
  end

  defp parse_masters(parts) do
    parts
    |> indexed_parts(~r{^ppt/slideMasters/slideMaster(\d+)\.xml$})
    |> Map.new(fn {index, xml} ->
      {index, %{placeholders: parse_placeholders(xml)}}
    end)
  end

  defp parse_layouts(parts, masters) do
    fallback_master = masters |> Map.keys() |> Enum.min(fn -> nil end)

    parts
    |> indexed_parts(~r{^ppt/slideLayouts/slideLayout(\d+)\.xml$})
    |> Map.new(fn {index, xml} ->
      master_index = layout_master_index(parts, index, masters) || fallback_master
      master_placeholders = get_in(masters, [master_index, :placeholders]) || []

      placeholders =
        xml
        |> parse_placeholders()
        |> Enum.map(&resolve_box(&1, master_placeholders))

      {index,
       %{
         index: index,
         name: attribute(first_element(xml, "p:cSld"), "name"),
         type: attribute(first_element(xml, "p:sldLayout"), "type"),
         master_index: master_index,
         placeholders: placeholders
       }}
    end)
  end

  defp indexed_parts(parts, regex) do
    for {partname, data} <- parts,
        [_, digits] <- [Regex.run(regex, partname)],
        into: %{},
        do: {String.to_integer(digits), to_string(data)}
  end

  defp layout_master_index(parts, layout_index, masters) do
    layout_partname = "ppt/slideLayouts/slideLayout#{layout_index}.xml"
    rels_partname = "ppt/slideLayouts/_rels/slideLayout#{layout_index}.xml.rels"

    with xml when not is_nil(xml) <- Map.get(parts, rels_partname),
         rels = Relationships.parse(to_string(xml)),
         {_rid, target} <- Relationships.find_by_type(rels, Constants.rt(:slide_master)),
         partname = Package.resolve_partname(layout_partname, target),
         [_, digits] <- Regex.run(~r{^ppt/slideMasters/slideMaster(\d+)\.xml$}, partname) do
      index = String.to_integer(digits)
      if Map.has_key?(masters, index), do: index
    else
      _ -> nil
    end
  end

  # A layout placeholder without its own <a:xfrm> takes the box of the master
  # placeholder found by type, first in document order.
  defp resolve_box(%{box: box} = ph, _master_placeholders) when not is_nil(box), do: ph

  defp resolve_box(ph, master_placeholders) do
    box =
      case inherit_type(ph.type) do
        nil ->
          nil

        type ->
          master_placeholders
          |> Enum.find(&(&1.type == type))
          |> case do
            nil -> nil
            master_ph -> master_ph.box
          end
      end

    %{ph | box: box}
  end

  defp inherit_type(type) when type in ["ctrTitle", "title"], do: "title"

  defp inherit_type(type)
       when type in ["body", "subTitle", "obj", "chart", "tbl", "pic", "clipArt", "dgm", "media"],
       do: "body"

  defp inherit_type(type) when type in ["dt", "ftr", "sldNum"], do: type
  defp inherit_type(_type), do: nil

  # --- Regex XML reading ---
  #
  # Runtime XML handling in Podium is regex based; sweet_xml is a test-only
  # dependency. Only shape blocks that carry a <p:ph/> are looked at, so
  # decorative shapes and pictures are skipped.

  @shape_re ~r{<p:(sp|pic)(?:\s[^>]*?)?>(.*?)</p:\1>}s

  defp parse_placeholders(xml) do
    @shape_re
    |> Regex.scan(xml)
    |> Enum.flat_map(fn [_full, _tag, block] ->
      case first_element(block, "p:ph") do
        nil -> []
        element -> [placeholder_from(element, block)]
      end
    end)
  end

  defp placeholder_from(ph_element, block) do
    %{
      type: attribute(ph_element, "type") || "obj",
      idx: integer_attribute(ph_element, "idx") || 0,
      name: attribute(first_element(block, "p:cNvPr"), "name"),
      box: own_box(block)
    }
  end

  # The shape's own position, read from the <a:xfrm> inside its <p:spPr>.
  defp own_box(block) do
    with [_, sp_pr] <- Regex.run(~r{<p:spPr(?:\s[^>]*?)?>(.*?)</p:spPr>}s, block),
         [_, xfrm] <- Regex.run(~r{<a:xfrm(?:\s[^>]*?)?>(.*?)</a:xfrm>}s, sp_pr),
         off when is_binary(off) <- first_element(xfrm, "a:off"),
         ext when is_binary(ext) <- first_element(xfrm, "a:ext"),
         x when is_integer(x) <- integer_attribute(off, "x"),
         y when is_integer(y) <- integer_attribute(off, "y"),
         w when is_integer(w) <- integer_attribute(ext, "cx"),
         h when is_integer(h) <- integer_attribute(ext, "cy") do
      %{x: x, y: y, w: w, h: h}
    else
      _ -> nil
    end
  end

  defp first_element(nil, _name), do: nil

  defp first_element(xml, name) do
    case Regex.run(~r{<#{Regex.escape(name)}(?:\s[^>]*?)?/?>}, xml) do
      [element] -> element
      nil -> nil
    end
  end

  defp attribute(nil, _name), do: nil

  defp attribute(element, name) do
    case Regex.run(~r/\s#{name}="([^"]*)"/, element) do
      [_, value] -> unescape(value)
      nil -> nil
    end
  end

  defp integer_attribute(element, name) do
    case Regex.run(~r/\s#{name}="(-?\d+)"/, element) do
      [_, value] -> String.to_integer(value)
      nil -> nil
    end
  end

  defp unescape(value) do
    value
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
    |> String.replace("&amp;", "&")
  end
end
