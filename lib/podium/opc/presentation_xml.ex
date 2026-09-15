defmodule Podium.OPC.PresentationXml do
  @moduledoc """
  Surgery on an existing `ppt/presentation.xml` string.

  Podium builds presentations on top of a template package rather than writing
  `presentation.xml` from scratch, so everything the template declares (notes
  size, default text style, embedded fonts, custom show properties) survives.
  These functions edit the parts Podium owns: the slide size, the slide id list,
  the notes master id list, and PowerPoint's section list.

  Editing is regex-based, matching the rest of Podium's runtime XML handling.
  """

  # PowerPoint sections. The extension references slide ids that Podium
  # reissues from 256, which makes PowerPoint offer to repair the file.
  @section_list_uri "{521415D9-36F7-43E2-AB2F-B90AF26B5E84}"

  @slide_size_re ~r/<p:sldSz\b[^>]*\/>/

  @doc """
  Returns `{cx, cy}` from `<p:sldSz/>`, or `nil` when the element is absent or
  malformed.
  """
  @spec slide_size(String.t()) :: {non_neg_integer(), non_neg_integer()} | nil
  def slide_size(xml) when is_binary(xml) do
    with [element] <- Regex.run(@slide_size_re, xml),
         cx when is_integer(cx) <- integer_attribute(element, "cx"),
         cy when is_integer(cy) <- integer_attribute(element, "cy") do
      {cx, cy}
    else
      _ -> nil
    end
  end

  @doc """
  Replaces `<p:sldSz/>` with one of the given size.

  Any other attribute (notably `type="screen4x3"`) is dropped, since it would
  contradict the new dimensions.
  """
  @spec put_slide_size(String.t(), non_neg_integer(), non_neg_integer()) :: String.t()
  def put_slide_size(xml, cx, cy) when is_binary(xml) do
    Regex.replace(@slide_size_re, xml, ~s(<p:sldSz cx="#{cx}" cy="#{cy}"/>), global: false)
  end

  @doc """
  Replaces the `<p:sldIdLst>` with one listing `entries`, a list of
  `{slide_id, rid}` tuples.

  An empty list leaves no list at all, which is what a slide-less template
  wants. A new list is inserted in schema order: after the handout master list
  if there is one, else after the notes master list, else after the slide master
  list.
  """
  @spec put_slide_id_list(String.t(), [{pos_integer(), String.t()}]) :: String.t()
  def put_slide_id_list(xml, entries) when is_binary(xml) and is_list(entries) do
    xml = remove_element(xml, "p:sldIdLst")

    case entries do
      [] ->
        xml

      entries ->
        list =
          entries
          |> Enum.map_join(fn {id, rid} -> ~s(<p:sldId id="#{id}" r:id="#{rid}"/>) end)
          |> then(&"<p:sldIdLst>#{&1}</p:sldIdLst>")

        insert_after_first(
          xml,
          ["p:handoutMasterIdLst", "p:notesMasterIdLst", "p:sldMasterIdLst"],
          list
        )
    end
  end

  @doc """
  Inserts a `<p:notesMasterIdLst>` naming `rid`, unless the XML already has one.
  """
  @spec put_notes_master_id(String.t(), String.t()) :: String.t()
  def put_notes_master_id(xml, rid) when is_binary(xml) do
    if element_present?(xml, "p:notesMasterIdLst") do
      xml
    else
      list =
        ~s(<p:notesMasterIdLst><p:notesMasterId r:id="#{rid}"/></p:notesMasterIdLst>)

      insert_after_first(xml, ["p:sldMasterIdLst"], list)
    end
  end

  @doc """
  Removes PowerPoint's section list extension, and the `<p:extLst>` around it
  when that leaves it empty.
  """
  @spec strip_section_list(String.t()) :: String.t()
  def strip_section_list(xml) when is_binary(xml) do
    xml
    |> String.replace(
      ~r/<p:ext\s+uri="#{Regex.escape(@section_list_uri)}"\s*>.*?<\/p:ext>/s,
      ""
    )
    |> String.replace(~r/<p:extLst\s*>\s*<\/p:extLst>/, "")
  end

  # Removes `<name>...</name>` and the self-closing `<name/>` form.
  defp remove_element(xml, name) do
    xml
    |> String.replace(~r/<#{Regex.escape(name)}(?:\s[^>]*)?>.*?<\/#{Regex.escape(name)}>/s, "")
    |> String.replace(~r/<#{Regex.escape(name)}(?:\s[^>]*)?\/>/, "")
  end

  defp element_present?(xml, name) do
    Regex.match?(~r/<#{Regex.escape(name)}(?:\s[^>]*)?(?:\/)?>/, xml)
  end

  # Inserts `fragment` after the first of `names` that appears, taking the
  # closing tag (or the self-closing element) as the insertion point.
  defp insert_after_first(xml, names, fragment) do
    Enum.find_value(names, xml, fn name ->
      anchor =
        Regex.run(~r/<#{Regex.escape(name)}(?:\s[^>]*)?\/>/, xml, return: :index) ||
          Regex.run(~r/<\/#{Regex.escape(name)}>/, xml, return: :index)

      case anchor do
        [{start, length}] ->
          at = start + length
          binary_part(xml, 0, at) <> fragment <> binary_part(xml, at, byte_size(xml) - at)

        nil ->
          nil
      end
    end)
  end

  defp integer_attribute(element, name) do
    case Regex.run(~r/\s#{name}="(\d+)"/, element) do
      [_, value] -> String.to_integer(value)
      nil -> nil
    end
  end
end
