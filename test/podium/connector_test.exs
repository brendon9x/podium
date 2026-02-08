defmodule Podium.ConnectorTest do
  use ExUnit.Case, async: true

  alias Podium.{Connector, Test.PptxHelpers}

  describe "straight connector" do
    test "generates <p:cxnSp> element with prst='line'" do
      conn =
        Connector.new(2, :straight, {1, :inches}, {1, :inches}, {5, :inches}, {3, :inches})

      xml = Connector.to_xml(conn)

      assert xml =~ "<p:cxnSp"
      assert xml =~ ~s(prst="line")
      assert xml =~ "<p:nvCxnSpPr>"
      assert xml =~ "</p:cxnSp>"
    end
  end

  describe "elbow connector" do
    test "generates prst='bentConnector3'" do
      conn =
        Connector.new(2, :elbow, {1, :inches}, {1, :inches}, {5, :inches}, {3, :inches})

      xml = Connector.to_xml(conn)
      assert xml =~ ~s(prst="bentConnector3")
    end
  end

  describe "curved connector" do
    test "generates prst='curvedConnector3'" do
      conn =
        Connector.new(2, :curved, {1, :inches}, {1, :inches}, {5, :inches}, {3, :inches})

      xml = Connector.to_xml(conn)
      assert xml =~ ~s(prst="curvedConnector3")
    end
  end

  describe "flip calculations" do
    test "begin_x > end_x sets flipH" do
      conn =
        Connector.new(2, :straight, {5, :inches}, {1, :inches}, {1, :inches}, {3, :inches})

      assert conn.flip_h == true
      assert conn.flip_v == false

      xml = Connector.to_xml(conn)
      assert xml =~ ~s(flipH="1")
      refute xml =~ ~s(flipV="1")
    end

    test "begin_y > end_y sets flipV" do
      conn =
        Connector.new(2, :straight, {1, :inches}, {5, :inches}, {3, :inches}, {1, :inches})

      assert conn.flip_h == false
      assert conn.flip_v == true

      xml = Connector.to_xml(conn)
      refute xml =~ ~s(flipH="1")
      assert xml =~ ~s(flipV="1")
    end

    test "both flips when begin > end in both dimensions" do
      conn =
        Connector.new(2, :straight, {5, :inches}, {5, :inches}, {1, :inches}, {1, :inches})

      assert conn.flip_h == true
      assert conn.flip_v == true

      xml = Connector.to_xml(conn)
      assert xml =~ ~s(flipH="1")
      assert xml =~ ~s(flipV="1")
    end

    test "no flips when begin < end in both dimensions" do
      conn =
        Connector.new(2, :straight, {1, :inches}, {1, :inches}, {5, :inches}, {5, :inches})

      assert conn.flip_h == false
      assert conn.flip_v == false

      xml = Connector.to_xml(conn)
      refute xml =~ "flipH"
      refute xml =~ "flipV"
    end
  end

  describe "bounding box" do
    test "x and y are min of begin/end" do
      conn =
        Connector.new(2, :straight, {5, :inches}, {3, :inches}, {1, :inches}, {1, :inches})

      # min(5in, 1in) = 1in = 914400
      assert conn.x == 914_400
      # min(3in, 1in) = 1in = 914400
      assert conn.y == 914_400
    end

    test "width and height are abs of diff" do
      conn =
        Connector.new(2, :straight, {5, :inches}, {3, :inches}, {1, :inches}, {1, :inches})

      # abs(1in - 5in) = 4in = 3657600
      assert conn.width == 3_657_600
      # abs(1in - 3in) = 2in = 1828800
      assert conn.height == 1_828_800
    end
  end

  describe "line formatting" do
    test "line with color and width" do
      conn =
        Connector.new(
          2,
          :straight,
          {1, :inches},
          {1, :inches},
          {5, :inches},
          {3, :inches},
          line: [color: "FF0000", width: {2, :pt}]
        )

      xml = Connector.to_xml(conn)
      assert xml =~ ~s(<a:ln w="25400">)
      assert xml =~ ~s(<a:srgbClr val="FF0000"/>)
    end

    test "line with dash style" do
      conn =
        Connector.new(
          2,
          :elbow,
          {1, :inches},
          {1, :inches},
          {5, :inches},
          {3, :inches},
          line: [color: "000000", dash_style: :dash]
        )

      xml = Connector.to_xml(conn)
      assert xml =~ ~s(<a:prstDash val="dash"/>)
    end

    test "no line option renders no <a:ln> in spPr" do
      conn =
        Connector.new(2, :straight, {1, :inches}, {1, :inches}, {5, :inches}, {3, :inches})

      xml = Connector.to_xml(conn)
      # The spPr section should not contain <a:ln> (the <a:lnRef> in style is fine)
      [sp_pr] = Regex.run(~r/<p:spPr>.*<\/p:spPr>/s, xml)
      refute sp_pr =~ "<a:ln>"
      refute sp_pr =~ "<a:ln "
    end
  end

  describe "style element" do
    test "connectors include <p:style>" do
      conn =
        Connector.new(2, :straight, {1, :inches}, {1, :inches}, {5, :inches}, {3, :inches})

      xml = Connector.to_xml(conn)
      assert xml =~ "<p:style>"
      assert xml =~ "</p:style>"
    end
  end

  describe "integration" do
    test "valid pptx with connectors" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        slide
        |> Podium.add_connector(:straight, {1, :inches}, {1, :inches}, {5, :inches}, {3, :inches})
        |> Podium.add_connector(:elbow, {1, :inches}, {4, :inches}, {5, :inches}, {6, :inches},
          line: [color: "FF0000", width: {2, :pt}]
        )
        |> Podium.add_connector(:curved, {6, :inches}, {1, :inches}, {10, :inches}, {4, :inches})

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "<p:cxnSp"
      assert slide_xml =~ ~s(prst="line")
      assert slide_xml =~ ~s(prst="bentConnector3")
      assert slide_xml =~ ~s(prst="curvedConnector3")
    end
  end
end
