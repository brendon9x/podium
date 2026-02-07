defmodule Podium.TextTest do
  use ExUnit.Case, async: true

  alias Podium.Text

  describe "normalize/2" do
    test "plain string produces single paragraph with single run" do
      result = Text.normalize("Hello")
      assert [%{runs: [%{text: "Hello", opts: []}], alignment: nil}] = result
    end

    test "plain string with font_size passes it to run opts" do
      result = Text.normalize("Hello", font_size: 24)
      assert [%{runs: [%{text: "Hello", opts: [font_size: 24]}]}] = result
    end

    test "list of run lists produces multiple paragraphs" do
      result = Text.normalize([["First"], ["Second"]])
      assert length(result) == 2
      assert hd(result).runs == [%{text: "First", opts: []}]
    end

    test "tuple runs with opts" do
      result = Text.normalize([[{"Bold", bold: true}]])
      assert [%{runs: [%{text: "Bold", opts: [bold: true]}]}] = result
    end

    test "paragraph tuple with alignment" do
      result = Text.normalize([{[{"Title"}], alignment: :center}])
      assert [%{alignment: :center}] = result
    end

    test "default alignment propagates to paragraphs without explicit alignment" do
      result = Text.normalize([["Text"]], alignment: :right)
      assert [%{alignment: :right}] = result
    end

    test "per-paragraph alignment overrides default" do
      result = Text.normalize([{["Text"], alignment: :left}], alignment: :right)
      assert [%{alignment: :left}] = result
    end
  end

  describe "paragraphs_xml/1" do
    test "generates simple paragraph" do
      paragraphs = Text.normalize("Hello")
      xml = Text.paragraphs_xml(paragraphs)

      assert xml =~ "<a:p>"
      assert xml =~ "<a:r>"
      assert xml =~ "<a:t>Hello</a:t>"
      assert xml =~ "</a:p>"
    end

    test "includes bold attribute" do
      paragraphs = Text.normalize([[{"Bold text", bold: true}]])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(b="1")
    end

    test "includes alignment" do
      paragraphs = Text.normalize("Centered", alignment: :center)
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(algn="ctr")
    end

    test "includes color as solidFill" do
      paragraphs = Text.normalize([[{"Red", color: "FF0000"}]])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
    end

    test "includes font as latin typeface" do
      paragraphs = Text.normalize([[{"Custom", font: "Calibri"}]])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(<a:latin typeface="Calibri"/>)
    end

    test "includes strikethrough" do
      paragraphs = Text.normalize([[{"Struck", strikethrough: true}]])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(strike="sngStrike")
    end

    test "includes superscript baseline" do
      paragraphs = Text.normalize([[{"2", superscript: true}]])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(baseline="30000")
    end

    test "includes subscript baseline" do
      paragraphs = Text.normalize([[{"2", subscript: true}]])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(baseline="-25000")
    end

    test "paragraph line spacing" do
      paragraphs = Text.normalize([{["Spaced"], line_spacing: 1.5}])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(<a:lnSpc><a:spcPct val="150000"/></a:lnSpc>)
    end

    test "paragraph space before and after" do
      paragraphs = Text.normalize([{["Text"], space_before: 6, space_after: 12}])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(<a:spcBef><a:spcPts val="600"/></a:spcBef>)
      assert xml =~ ~s(<a:spcAft><a:spcPts val="1200"/></a:spcAft>)
    end

    test "default bullet character" do
      paragraphs = Text.normalize([{["Item"], bullet: true}])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(marL="457200")
      assert xml =~ ~s(indent="-228600")
      assert xml =~ ~s(<a:buChar char="&#x2022;"/>)
    end

    test "custom bullet character" do
      paragraphs = Text.normalize([{["Item"], bullet: "–"}])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(<a:buChar char="–"/>)
    end

    test "numbered bullet" do
      paragraphs = Text.normalize([{["Step one"], bullet: :number}])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(<a:buAutoNum type="arabicPeriod"/>)
    end

    test "bullet with indent level" do
      paragraphs = Text.normalize([{["Sub-item"], bullet: true, level: 1}])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(lvl="1")
      assert xml =~ ~s(marL="914400")
      assert xml =~ ~s(indent="-228600")
    end

    test "language tag on run" do
      paragraphs = Text.normalize([[{"Polish text", lang: "pl-PL"}]])
      xml = Text.paragraphs_xml(paragraphs)
      assert xml =~ ~s(lang="pl-PL")
    end

    test "no pPr emitted when no paragraph properties" do
      paragraphs = Text.normalize([["Plain text"]])
      xml = Text.paragraphs_xml(paragraphs)
      refute xml =~ "<a:pPr"
    end
  end
end
