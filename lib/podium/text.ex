defmodule Podium.Text do
  @moduledoc false

  alias Podium.XML.Builder

  @doc """
  Normalizes text input into a canonical list of paragraph maps.

  Accepts:
    - A plain string: `"Hello"`
    - A list of paragraphs where each paragraph is:
      - A list of runs: `[{"bold text", bold: true}, "plain"]`
      - A `{runs, para_opts}` tuple: `{[{"Title", bold: true}], alignment: :center}`
  """
  def normalize(text, opts \\ []) when is_binary(text) or is_list(text) do
    default_alignment = Keyword.get(opts, :alignment)
    default_font_size = Keyword.get(opts, :font_size)

    paragraphs =
      case text do
        text when is_binary(text) ->
          run_opts = if default_font_size, do: [font_size: default_font_size], else: []

          [
            %{
              runs: [%{text: text, opts: run_opts}],
              alignment: default_alignment,
              line_spacing: nil,
              space_before: nil,
              space_after: nil,
              bullet: nil,
              level: 0
            }
          ]

        paragraphs when is_list(paragraphs) ->
          Enum.map(paragraphs, fn para -> normalize_paragraph(para, default_alignment) end)
      end

    paragraphs
  end

  defp normalize_paragraph({runs, para_opts}, default_alignment) when is_list(runs) do
    %{
      runs: Enum.map(runs, &normalize_run/1),
      alignment: Keyword.get(para_opts, :alignment, default_alignment),
      line_spacing: Keyword.get(para_opts, :line_spacing),
      space_before: Keyword.get(para_opts, :space_before),
      space_after: Keyword.get(para_opts, :space_after),
      bullet: Keyword.get(para_opts, :bullet),
      level: Keyword.get(para_opts, :level, 0)
    }
  end

  defp normalize_paragraph(runs, default_alignment) when is_list(runs) do
    %{
      runs: Enum.map(runs, &normalize_run/1),
      alignment: default_alignment,
      line_spacing: nil,
      space_before: nil,
      space_after: nil,
      bullet: nil,
      level: 0
    }
  end

  defp normalize_run(:line_break), do: %{text: :line_break, opts: []}
  defp normalize_run(text) when is_binary(text), do: %{text: text, opts: []}
  defp normalize_run({text}) when is_binary(text), do: %{text: text, opts: []}
  defp normalize_run({text, opts}) when is_binary(text), do: %{text: text, opts: opts}

  @doc """
  Generates the XML for a list of normalized paragraphs (the <a:p> elements).
  Optionally accepts a `hyperlink_rids` map of `%{url => rId}` for resolving hyperlinks.
  """
  def paragraphs_xml(paragraphs, hyperlink_rids \\ %{}) do
    paragraphs
    |> Enum.map(&paragraph_xml(&1, hyperlink_rids))
    |> Enum.join()
  end

  defp paragraph_xml(para, hyperlink_rids) do
    ppr = paragraph_properties_xml(para)
    runs_xml = Enum.map(para.runs, &run_xml(&1, hyperlink_rids)) |> Enum.join()
    "<a:p>#{ppr}#{runs_xml}</a:p>"
  end

  defp paragraph_properties_xml(para) do
    attrs = ppr_attrs(para)
    children = ppr_children(para)

    case {attrs, children} do
      {[], ""} -> ""
      {attrs, ""} -> ~s(<a:pPr #{Enum.join(attrs, " ")}/>)
      {[], children} -> "<a:pPr>#{children}</a:pPr>"
      {attrs, children} -> ~s(<a:pPr #{Enum.join(attrs, " ")}>#{children}</a:pPr>)
    end
  end

  defp ppr_attrs(para) do
    attrs = []

    attrs =
      if para.alignment, do: attrs ++ [~s(algn="#{alignment_value(para.alignment)}")], else: attrs

    attrs =
      if para.bullet do
        level = para.level || 0
        mar_l = (level + 1) * 457_200
        attrs ++ [~s(lvl="#{level}"), ~s(marL="#{mar_l}"), ~s(indent="-228600")]
      else
        attrs
      end

    attrs
  end

  defp ppr_children(para) do
    spacing = spacing_xml(para)
    bullet = bullet_xml(para.bullet)
    spacing <> bullet
  end

  defp spacing_xml(para) do
    line_spacing_xml(para.line_spacing) <>
      space_before_xml(para.space_before) <>
      space_after_xml(para.space_after)
  end

  defp line_spacing_xml(nil), do: ""

  defp line_spacing_xml(factor) do
    val = round(factor * 100_000)
    ~s(<a:lnSpc><a:spcPct val="#{val}"/></a:lnSpc>)
  end

  defp space_before_xml(nil), do: ""
  defp space_before_xml(pts), do: ~s(<a:spcBef><a:spcPts val="#{pts * 100}"/></a:spcBef>)

  defp space_after_xml(nil), do: ""
  defp space_after_xml(pts), do: ~s(<a:spcAft><a:spcPts val="#{pts * 100}"/></a:spcAft>)

  defp bullet_xml(nil), do: ""
  defp bullet_xml(false), do: ""
  defp bullet_xml(true), do: ~s(<a:buChar char="&#x2022;"/>)
  defp bullet_xml(:number), do: ~s(<a:buAutoNum type="arabicPeriod"/>)
  defp bullet_xml(char) when is_binary(char), do: ~s(<a:buChar char="#{char}"/>)

  defp alignment_value(:left), do: "l"
  defp alignment_value(:center), do: "ctr"
  defp alignment_value(:right), do: "r"
  defp alignment_value(:justify), do: "just"

  defp underline_value(true), do: "sng"
  defp underline_value(:single), do: "sng"
  defp underline_value(:double), do: "dbl"
  defp underline_value(:heavy), do: "heavy"
  defp underline_value(:dotted), do: "dotted"
  defp underline_value(:dotted_heavy), do: "dottedHeavy"
  defp underline_value(:dash), do: "dash"
  defp underline_value(:dash_heavy), do: "dashHeavy"
  defp underline_value(:dash_long), do: "dashLong"
  defp underline_value(:dash_long_heavy), do: "dashLongHeavy"
  defp underline_value(:dot_dash), do: "dotDash"
  defp underline_value(:dot_dash_heavy), do: "dotDashHeavy"
  defp underline_value(:dot_dot_dash), do: "dotDotDash"
  defp underline_value(:dot_dot_dash_heavy), do: "dotDotDashHeavy"
  defp underline_value(:wavy), do: "wavy"
  defp underline_value(:wavy_heavy), do: "wavyHeavy"
  defp underline_value(:wavy_double), do: "wavyDbl"
  defp underline_value(:words), do: "words"

  defp run_xml(%{text: :line_break, opts: _opts}, _hyperlink_rids) do
    "<a:br/>"
  end

  defp run_xml(%{text: text, opts: opts}, hyperlink_rids) when is_binary(text) do
    rpr = run_properties_xml(opts, hyperlink_rids)

    case String.split(text, "\n") do
      [single] ->
        escaped_text = Builder.escape(single)
        "<a:r>#{rpr}<a:t>#{escaped_text}</a:t></a:r>"

      segments ->
        segments
        |> Enum.map(fn segment ->
          escaped = Builder.escape(segment)
          "<a:r>#{rpr}<a:t>#{escaped}</a:t></a:r>"
        end)
        |> Enum.intersperse("<a:br/>")
        |> Enum.join()
    end
  end

  defp run_properties_xml([], _hyperlink_rids), do: ~s(<a:rPr lang="en-US" dirty="0"/>)

  defp run_properties_xml(opts, hyperlink_rids) do
    attrs = base_run_attrs(opts)
    children = run_children_xml(opts, hyperlink_rids)

    if children == "" do
      ~s(<a:rPr #{attrs}/>)
    else
      ~s(<a:rPr #{attrs}>#{children}</a:rPr>)
    end
  end

  defp base_run_attrs(opts) do
    lang = Keyword.get(opts, :lang, "en-US")
    attrs = [~s(lang="#{lang}")]

    attrs =
      if font_size = Keyword.get(opts, :font_size) do
        attrs ++ [~s(sz="#{font_size * 100}")]
      else
        attrs
      end

    attrs = if Keyword.get(opts, :bold), do: attrs ++ [~s(b="1")], else: attrs
    attrs = if Keyword.get(opts, :italic), do: attrs ++ [~s(i="1")], else: attrs

    attrs =
      case Keyword.get(opts, :underline) do
        nil -> attrs
        false -> attrs
        value -> attrs ++ [~s(u="#{underline_value(value)}")]
      end

    attrs =
      if Keyword.get(opts, :strikethrough), do: attrs ++ [~s(strike="sngStrike")], else: attrs

    attrs =
      cond do
        Keyword.get(opts, :superscript) -> attrs ++ [~s(baseline="30000")]
        Keyword.get(opts, :subscript) -> attrs ++ [~s(baseline="-25000")]
        true -> attrs
      end

    attrs = attrs ++ [~s(dirty="0")]

    Enum.join(attrs, " ")
  end

  defp run_children_xml(opts, hyperlink_rids) do
    color_xml = color_child_xml(Keyword.get(opts, :color))
    font_xml = font_child_xml(Keyword.get(opts, :font))
    hyperlink_xml = hyperlink_child_xml(Keyword.get(opts, :hyperlink), hyperlink_rids)
    color_xml <> font_xml <> hyperlink_xml
  end

  defp color_child_xml(nil), do: ""
  defp color_child_xml(color), do: ~s(<a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>)

  defp font_child_xml(nil), do: ""
  defp font_child_xml(font), do: ~s(<a:latin typeface="#{font}"/>)

  defp hyperlink_child_xml(nil, _rids), do: ""

  defp hyperlink_child_xml(url, rids) when is_binary(url) do
    case Map.get(rids, url) do
      nil -> ""
      rid -> ~s(<a:hlinkClick r:id="#{rid}"/>)
    end
  end

  defp hyperlink_child_xml(opts, rids) when is_list(opts) do
    url = Keyword.fetch!(opts, :url)
    tooltip = Keyword.get(opts, :tooltip)

    case Map.get(rids, url) do
      nil ->
        ""

      rid ->
        tooltip_attr = if tooltip, do: ~s( tooltip="#{Builder.escape(tooltip)}"), else: ""
        ~s(<a:hlinkClick r:id="#{rid}"#{tooltip_attr}/>)
    end
  end

  @doc """
  Collects all unique hyperlink URLs from normalized paragraphs.
  """
  def collect_hyperlink_urls(paragraphs) do
    paragraphs
    |> Enum.flat_map(fn para ->
      Enum.flat_map(para.runs, fn run ->
        case Keyword.get(run.opts, :hyperlink) do
          nil -> []
          url when is_binary(url) -> [url]
          opts when is_list(opts) -> [Keyword.fetch!(opts, :url)]
        end
      end)
    end)
    |> Enum.uniq()
  end
end
