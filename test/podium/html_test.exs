defmodule Podium.HTMLTest do
  use ExUnit.Case, async: true

  alias Podium.HTML

  describe "html?/1" do
    test "detects simple HTML tags" do
      assert HTML.html?("<b>bold</b>")
      assert HTML.html?("<p>paragraph</p>")
      assert HTML.html?("<span>text</span>")
      assert HTML.html?("<br/>")
      assert HTML.html?("<br>")
    end

    test "detects tags with attributes" do
      assert HTML.html?(~s(<span style="color: red">text</span>))
      assert HTML.html?(~s(<p class="intro">text</p>))
    end

    test "rejects plain strings" do
      refute HTML.html?("Hello world")
      refute HTML.html?("No tags here")
      refute HTML.html?("")
    end

    test "rejects angle brackets that aren't tags" do
      refute HTML.html?("5 < 10 and 20 > 15")
      refute HTML.html?("a < b")
      refute HTML.html?("use <= operator")
    end

    test "detects self-closing tags" do
      assert HTML.html?("<br/>")
      assert HTML.html?("<br />")
    end
  end

  describe "parse/1 - inline formatting" do
    test "bold with <b>" do
      [para] = HTML.parse("<b>bold</b>")
      assert [%{text: "bold", opts: [bold: true]}] = para.runs
    end

    test "bold with <strong>" do
      [para] = HTML.parse("<strong>bold</strong>")
      assert [%{text: "bold", opts: [bold: true]}] = para.runs
    end

    test "italic with <i>" do
      [para] = HTML.parse("<i>italic</i>")
      assert [%{text: "italic", opts: [italic: true]}] = para.runs
    end

    test "italic with <em>" do
      [para] = HTML.parse("<em>italic</em>")
      assert [%{text: "italic", opts: [italic: true]}] = para.runs
    end

    test "underline with <u>" do
      [para] = HTML.parse("<u>underlined</u>")
      assert [%{text: "underlined", opts: [underline: true]}] = para.runs
    end

    test "strikethrough with <s>" do
      [para] = HTML.parse("<s>struck</s>")
      assert [%{text: "struck", opts: [strikethrough: true]}] = para.runs
    end

    test "strikethrough with <del>" do
      [para] = HTML.parse("<del>deleted</del>")
      assert [%{text: "deleted", opts: [strikethrough: true]}] = para.runs
    end

    test "superscript with <sup>" do
      [para] = HTML.parse("<sup>2</sup>")
      assert [%{text: "2", opts: [superscript: true]}] = para.runs
    end

    test "subscript with <sub>" do
      [para] = HTML.parse("<sub>2</sub>")
      assert [%{text: "2", opts: [subscript: true]}] = para.runs
    end

    test "nested formatting" do
      [para] = HTML.parse("<b><i>bold italic</i></b>")
      assert [%{text: "bold italic", opts: opts}] = para.runs
      assert opts[:bold] == true
      assert opts[:italic] == true
    end

    test "mixed inline and plain text" do
      [para] = HTML.parse("Hello <b>world</b>!")

      assert [
               %{text: "Hello ", opts: []},
               %{text: "world", opts: [bold: true]},
               %{text: "!", opts: []}
             ] = para.runs
    end
  end

  describe "parse/1 - span styles" do
    test "color with hash hex" do
      [para] = HTML.parse(~s(<span style="color: #FF0000">red</span>))
      assert [%{text: "red", opts: [color: "FF0000"]}] = para.runs
    end

    test "color with shorthand hex" do
      [para] = HTML.parse(~s(<span style="color: #F00">red</span>))
      assert [%{text: "red", opts: [color: "FF0000"]}] = para.runs
    end

    test "font-size in pt" do
      [para] = HTML.parse(~s(<span style="font-size: 24pt">big</span>))
      assert [%{text: "big", opts: [font_size: 24]}] = para.runs
    end

    test "font-family" do
      [para] = HTML.parse(~s(<span style="font-family: Arial">text</span>))
      assert [%{text: "text", opts: [font: "Arial"]}] = para.runs
    end

    test "font-family with quotes and fallbacks" do
      [para] = HTML.parse(~s(<span style="font-family: 'Times New Roman', serif">text</span>))
      assert [%{text: "text", opts: [font: "Times New Roman"]}] = para.runs
    end

    test "multiple styles on span" do
      [para] =
        HTML.parse(
          ~s(<span style="color: #003366; font-size: 18pt; font-family: Calibri">styled</span>)
        )

      assert [%{text: "styled", opts: opts}] = para.runs
      assert opts[:color] == "003366"
      assert opts[:font_size] == 18
      assert opts[:font] == "Calibri"
    end

    test "span styles combine with inline tags" do
      [para] = HTML.parse(~s(<b><span style="color: #FF0000">bold red</span></b>))
      assert [%{text: "bold red", opts: opts}] = para.runs
      assert opts[:bold] == true
      assert opts[:color] == "FF0000"
    end
  end

  describe "parse/1 - paragraphs" do
    test "<p> tags create separate paragraphs" do
      paras = HTML.parse("<p>First</p><p>Second</p>")
      assert length(paras) == 2
      assert hd(paras).runs == [%{text: "First", opts: []}]
      assert List.last(paras).runs == [%{text: "Second", opts: []}]
    end

    test "<br> creates paragraph break" do
      paras = HTML.parse("Line 1<br>Line 2")
      assert length(paras) == 2
      assert hd(paras).runs == [%{text: "Line 1", opts: []}]
      assert List.last(paras).runs == [%{text: "Line 2", opts: []}]
    end

    test "<br/> self-closing creates paragraph break" do
      paras = HTML.parse("Line 1<br/>Line 2")
      assert length(paras) == 2
    end

    test "paragraph alignment via style" do
      [para] = HTML.parse(~s(<p style="text-align: center">Centered</p>))
      assert para.alignment == :center
    end

    test "paragraph alignment left" do
      [para] = HTML.parse(~s(<p style="text-align: left">Left</p>))
      assert para.alignment == :left
    end

    test "paragraph alignment right" do
      [para] = HTML.parse(~s(<p style="text-align: right">Right</p>))
      assert para.alignment == :right
    end

    test "paragraph alignment justify" do
      [para] = HTML.parse(~s(<p style="text-align: justify">Justified</p>))
      assert para.alignment == :justify
    end

    test "inline styles on <p> apply to children" do
      [para] = HTML.parse(~s(<p style="color: #003366; font-size: 18pt">styled para</p>))
      assert [%{text: "styled para", opts: opts}] = para.runs
      assert opts[:color] == "003366"
      assert opts[:font_size] == 18
    end
  end

  describe "parse/1 - lists" do
    test "unordered list" do
      paras = HTML.parse("<ul><li>Item 1</li><li>Item 2</li></ul>")
      assert length(paras) == 2
      assert Enum.all?(paras, &(&1.bullet == true))
      assert Enum.all?(paras, &(&1.level == 0))
    end

    test "ordered list" do
      paras = HTML.parse("<ol><li>Step 1</li><li>Step 2</li></ol>")
      assert length(paras) == 2
      assert Enum.all?(paras, &(&1.bullet == :number))
    end

    test "nested lists" do
      html = """
      <ul>
        <li>Top level</li>
        <ul>
          <li>Nested item</li>
        </ul>
      </ul>
      """

      paras = HTML.parse(html)
      top = Enum.find(paras, &(hd(&1.runs).text == "Top level"))
      nested = Enum.find(paras, &(hd(&1.runs).text == "Nested item"))

      assert top.level == 0
      assert nested.level == 1
    end

    test "ordered inside unordered" do
      html = "<ul><li>Bullet</li><ol><li>Number</li></ol></ul>"
      paras = HTML.parse(html)

      bullet_para = Enum.find(paras, &(hd(&1.runs).text == "Bullet"))
      number_para = Enum.find(paras, &(hd(&1.runs).text == "Number"))

      assert bullet_para.bullet == true
      assert number_para.bullet == :number
      assert number_para.level == 1
    end
  end

  describe "parse/1 - whitespace" do
    test "collapses consecutive whitespace" do
      [para] = HTML.parse("  Hello    world  ")
      assert [%{text: "Hello world", opts: []}] = para.runs
    end

    test "trims leading/trailing whitespace from paragraphs" do
      [para] = HTML.parse("<p>  text  </p>")
      assert [%{text: "text"}] = para.runs
    end

    test "newlines in source are collapsed" do
      [para] = HTML.parse("<b>Hello\n  world</b>")
      assert [%{text: "Hello world"}] = para.runs
    end
  end

  describe "parse/1 - HTML entities" do
    test "HTML entities are preserved by Floki" do
      [para] = HTML.parse("<p>5 &lt; 10 &amp; 20 &gt; 15</p>")
      text = Enum.map_join(para.runs, & &1.text)
      assert text =~ "5"
      assert text =~ "<"
      assert text =~ "10"
    end
  end

  describe "parse/1 - unknown tags passthrough" do
    test "unknown tags pass through their children" do
      [para] = HTML.parse("<custom>hello</custom>")
      assert [%{text: "hello", opts: []}] = para.runs
    end
  end

  describe "parse/1 - bare text" do
    test "bare text without block elements is a single paragraph" do
      [para] = HTML.parse("<b>Hello</b> <i>world</i>")
      assert length(para.runs) == 2
    end

    test "empty input returns empty paragraph" do
      [para] = HTML.parse("")
      assert para.runs == [%{text: "", opts: []}]
    end
  end

  describe "parse/1 - complex scenarios" do
    test "mixed paragraphs with formatting" do
      html = "<p><b>Title</b></p><p>Some <i>italic</i> and <u>underlined</u> text</p>"

      paras = HTML.parse(html)
      assert length(paras) == 2

      [title_para, body_para] = paras
      assert [%{text: "Title", opts: [bold: true]}] = title_para.runs

      # "Some " | "italic" | " and " | "underlined" | " text"
      assert length(body_para.runs) == 5
    end

    test "list with formatted items" do
      html = "<ul><li><b>Bold item</b></li><li>Plain item</li></ul>"
      paras = HTML.parse(html)
      assert length(paras) == 2

      [bold_item, plain_item] = paras
      assert [%{text: "Bold item", opts: [bold: true]}] = bold_item.runs
      assert bold_item.bullet == true
      assert [%{text: "Plain item", opts: []}] = plain_item.runs
      assert plain_item.bullet == true
    end

    test "deeply nested formatting" do
      [para] = HTML.parse("<b><i><u>all three</u></i></b>")
      assert [%{text: "all three", opts: opts}] = para.runs
      assert opts[:bold] == true
      assert opts[:italic] == true
      assert opts[:underline] == true
    end
  end
end
