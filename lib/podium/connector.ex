defmodule Podium.Connector do
  @moduledoc """
  Connector shapes between two points.

  Supports straight, elbow (bent), and curved connector types. Flip attributes
  are calculated automatically from start/end coordinates.
  """

  alias Podium.OPC.Constants
  alias Podium.{Drawing, Units}

  defstruct [
    :id,
    :name,
    :connector_type,
    :x,
    :y,
    :width,
    :height,
    :flip_h,
    :flip_v,
    :line
  ]

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          connector_type: String.t(),
          x: non_neg_integer(),
          y: non_neg_integer(),
          width: non_neg_integer(),
          height: non_neg_integer(),
          flip_h: boolean(),
          flip_v: boolean(),
          line: Podium.line() | nil
        }

  @type_map %{
    straight: "line",
    elbow: "bentConnector3",
    curved: "curvedConnector3"
  }

  @doc """
  Creates a new connector shape between two points.

  ## Parameters
    * `id` - shape ID within the slide
    * `connector_type` - `:straight`, `:elbow`, or `:curved`
    * `begin_x`, `begin_y` - start point coordinates
    * `end_x`, `end_y` - end point coordinates

  ## Options
    * `:line` - line color string or keyword list with `:color`, `:width`, `:dash_style`
  """
  @spec new(
          pos_integer(),
          Podium.connector_type(),
          Podium.dimension(),
          Podium.dimension(),
          Podium.dimension(),
          Podium.dimension(),
          keyword()
        ) :: t()
  def new(id, connector_type, begin_x, begin_y, end_x, end_y, opts \\ [])
      when connector_type in [:straight, :elbow, :curved] do
    bx = Units.to_emu(begin_x)
    by = Units.to_emu(begin_y)
    ex = Units.to_emu(end_x)
    ey = Units.to_emu(end_y)

    flip_h = bx > ex
    flip_v = by > ey

    x = min(bx, ex)
    y = min(by, ey)
    cx = abs(ex - bx)
    cy = abs(ey - by)

    prst = Map.fetch!(@type_map, connector_type)
    basename = connector_basename(connector_type)

    %__MODULE__{
      id: id,
      name: "#{basename} #{id - 1}",
      connector_type: prst,
      x: x,
      y: y,
      width: cx,
      height: cy,
      flip_h: flip_h,
      flip_v: flip_v,
      line: Keyword.get(opts, :line)
    }
  end

  @doc "Generates the `<p:cxnSp>` XML for the connector shape."
  @spec to_xml(t()) :: String.t()
  def to_xml(%__MODULE__{} = conn) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)

    flip_attrs = flip_attrs(conn.flip_h, conn.flip_v)

    line_out =
      case conn.line do
        nil -> ""
        line -> Drawing.line_xml(line)
      end

    ~s(<p:cxnSp xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvCxnSpPr>) <>
      ~s(<p:cNvPr id="#{conn.id}" name="#{conn.name}"/>) <>
      ~s(<p:cNvCxnSpPr/>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvCxnSpPr>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm#{flip_attrs}>) <>
      ~s(<a:off x="#{conn.x}" y="#{conn.y}"/>) <>
      ~s(<a:ext cx="#{conn.width}" cy="#{conn.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:prstGeom prst="#{conn.connector_type}"><a:avLst/></a:prstGeom>) <>
      line_out <>
      ~s(</p:spPr>) <>
      connector_style_xml() <>
      ~s(</p:cxnSp>)
  end

  defp flip_attrs(false, false), do: ""
  defp flip_attrs(true, false), do: ~s( flipH="1")
  defp flip_attrs(false, true), do: ~s( flipV="1")
  defp flip_attrs(true, true), do: ~s( flipH="1" flipV="1")

  defp connector_style_xml do
    ~s(<p:style>) <>
      ~s(<a:lnRef idx="2"><a:schemeClr val="accent1"/></a:lnRef>) <>
      ~s(<a:fillRef idx="0"><a:schemeClr val="accent1"/></a:fillRef>) <>
      ~s(<a:effectRef idx="1"><a:schemeClr val="accent1"/></a:effectRef>) <>
      ~s(<a:fontRef idx="minor"><a:schemeClr val="tx1"/></a:fontRef>) <>
      ~s(</p:style>)
  end

  defp connector_basename(:straight), do: "Straight Connector"
  defp connector_basename(:elbow), do: "Elbow Connector"
  defp connector_basename(:curved), do: "Curved Connector"
end
