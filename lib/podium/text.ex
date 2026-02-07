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

  defp normalize_run(text) when is_binary(text), do: %{text: text, opts: []}
  defp normalize_run({text}) when is_binary(text), do: %{text: text, opts: []}
  defp normalize_run({text, opts}) when is_binary(text), do: %{text: text, opts: opts}

  @doc """
  Generates the XML for a list of normalized paragraphs (the <a:p> elements).
  """
  def paragraphs_xml(paragraphs) do
    paragraphs
    |> Enum.map(&paragraph_xml/1)
    |> Enum.join()
  end

  defp paragraph_xml(para) do
    ppr = paragraph_properties_xml(para)
    runs_xml = Enum.map(para.runs, &run_xml/1) |> Enum.join()
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

  defp run_xml(%{text: text, opts: opts}) do
    rpr = run_properties_xml(opts)
    escaped_text = Builder.escape(text)
    "<a:r>#{rpr}<a:t>#{escaped_text}</a:t></a:r>"
  end

  defp run_properties_xml([]), do: ~s(<a:rPr lang="en-US" dirty="0"/>)

  defp run_properties_xml(opts) do
    attrs = base_run_attrs(opts)
    children = run_children_xml(opts)

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
    attrs = if Keyword.get(opts, :underline), do: attrs ++ [~s(u="sng")], else: attrs

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

  defp run_children_xml(opts) do
    color_xml = color_child_xml(Keyword.get(opts, :color))
    font_xml = font_child_xml(Keyword.get(opts, :font))
    color_xml <> font_xml
  end

  defp color_child_xml(nil), do: ""
  defp color_child_xml(color), do: ~s(<a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>)

  defp font_child_xml(nil), do: ""
  defp font_child_xml(font), do: ~s(<a:latin typeface="#{font}"/>)
end
