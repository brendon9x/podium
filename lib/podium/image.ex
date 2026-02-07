defmodule Podium.Image do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.Units

  defstruct [
    :image_index,
    :binary,
    :extension,
    :sha1,
    :x,
    :y,
    :width,
    :height,
    :crop,
    :rotation
  ]

  @doc """
  Creates a new image from binary data and position options.
  Extension is auto-detected from magic bytes.

  ## Options
    * `:crop` - keyword list with `:left`, `:right`, `:top`, `:bottom` (values in 1/1000ths of a percent, 0–100_000)
  """
  def new(binary, image_index, opts) when is_binary(binary) do
    extension = detect_extension(binary)
    sha1 = :crypto.hash(:sha, binary) |> Base.encode16(case: :lower)

    %__MODULE__{
      image_index: image_index,
      binary: binary,
      extension: extension,
      sha1: sha1,
      x: Units.to_emu(Keyword.fetch!(opts, :x)),
      y: Units.to_emu(Keyword.fetch!(opts, :y)),
      width: Units.to_emu(Keyword.fetch!(opts, :width)),
      height: Units.to_emu(Keyword.fetch!(opts, :height)),
      crop: Keyword.get(opts, :crop),
      rotation: Keyword.get(opts, :rotation)
    }
  end

  @doc """
  Returns the partname for the image media file.
  """
  def partname(%__MODULE__{image_index: idx, extension: ext}),
    do: "ppt/media/image#{idx}.#{ext}"

  @doc """
  Generates the <p:pic> XML for embedding the image in a slide.
  """
  def pic_xml(%__MODULE__{} = image, shape_id, r_id) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)

    crop_xml = src_rect_xml(image.crop)

    rot_attr = rotation_attr(image.rotation)

    ~s(<p:pic xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvPicPr>) <>
      ~s(<p:cNvPr id="#{shape_id}" name="Image #{image.image_index}"/>) <>
      ~s(<p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvPicPr>) <>
      ~s(<p:blipFill>) <>
      ~s(<a:blip r:embed="#{r_id}"/>) <>
      crop_xml <>
      ~s(<a:stretch><a:fillRect/></a:stretch>) <>
      ~s(</p:blipFill>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm#{rot_attr}>) <>
      ~s(<a:off x="#{image.x}" y="#{image.y}"/>) <>
      ~s(<a:ext cx="#{image.width}" cy="#{image.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>) <>
      ~s(</p:spPr>) <>
      ~s(</p:pic>)
  end

  defp src_rect_xml(nil), do: ""

  defp src_rect_xml(crop) when is_list(crop) do
    attrs =
      Enum.map([:left, :top, :right, :bottom], fn side ->
        case Keyword.get(crop, side) do
          nil -> nil
          val -> ~s(#{crop_attr(side)}="#{val}")
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    if attrs == "", do: "", else: ~s(<a:srcRect #{attrs}/>)
  end

  defp crop_attr(:left), do: "l"
  defp crop_attr(:top), do: "t"
  defp crop_attr(:right), do: "r"
  defp crop_attr(:bottom), do: "b"

  defp rotation_attr(nil), do: ""
  defp rotation_attr(degrees), do: ~s( rot="#{round(degrees * 60_000)}")

  defp detect_extension(<<0x89, 0x50, 0x4E, 0x47, _rest::binary>>), do: "png"
  defp detect_extension(<<0xFF, 0xD8, _rest::binary>>), do: "jpeg"
  defp detect_extension(<<0x42, 0x4D, _rest::binary>>), do: "bmp"
  defp detect_extension(<<0x47, 0x49, 0x46, _rest::binary>>), do: "gif"
  # TIFF little-endian
  defp detect_extension(<<0x49, 0x49, 0x2A, 0x00, _rest::binary>>), do: "tiff"
  # TIFF big-endian
  defp detect_extension(<<0x4D, 0x4D, 0x00, 0x2A, _rest::binary>>), do: "tiff"

  defp detect_extension(_binary),
    do: raise(ArgumentError, "unsupported image format (expected PNG, JPEG, BMP, GIF, or TIFF)")
end
