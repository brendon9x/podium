defmodule Podium.Image do
  @moduledoc """
  Embedded image with format auto-detection from magic bytes.

  Supports PNG, JPEG, BMP, GIF, TIFF, EMF, and WMF formats. Image dimensions
  are read from binary headers for automatic aspect-ratio sizing.
  """

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
    :rotation,
    shape: "rect"
  ]

  @type t :: %__MODULE__{
          image_index: pos_integer() | nil,
          binary: binary(),
          extension: String.t(),
          sha1: String.t(),
          x: integer(),
          y: integer(),
          width: non_neg_integer(),
          height: non_neg_integer(),
          crop: keyword() | nil,
          rotation: number() | nil,
          shape: String.t()
        }

  @doc """
  Creates a new image from binary data and position options.
  Extension is auto-detected from magic bytes.

  ## Options
    * `:crop` - keyword list with `:left`, `:right`, `:top`, `:bottom` (values in 1/1000ths of a percent, 0–100_000)
  """
  @spec new(binary(), keyword()) :: t()
  def new(binary, opts) when is_binary(binary) do
    extension = detect_extension(binary)
    sha1 = :crypto.hash(:sha, binary) |> Base.encode16(case: :lower)

    width_opt = Keyword.get(opts, :width)
    height_opt = Keyword.get(opts, :height)

    {width, height} = resolve_size(binary, extension, width_opt, height_opt)

    %__MODULE__{
      image_index: nil,
      binary: binary,
      extension: extension,
      sha1: sha1,
      x: Units.to_emu(Keyword.fetch!(opts, :x)),
      y: Units.to_emu(Keyword.fetch!(opts, :y)),
      width: width,
      height: height,
      crop: Keyword.get(opts, :crop),
      rotation: Keyword.get(opts, :rotation),
      shape: shape_preset(Keyword.get(opts, :shape, "rect"))
    }
  end

  @doc """
  Returns the partname for the image media file.
  """
  @spec partname(t()) :: String.t()
  def partname(%__MODULE__{image_index: idx, extension: ext}),
    do: "ppt/media/image#{idx}.#{ext}"

  @doc """
  Generates the <p:pic> XML for embedding the image in a slide.
  """
  @spec pic_xml(t(), pos_integer(), String.t()) :: String.t()
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
      ~s(<a:prstGeom prst="#{image.shape}"><a:avLst/></a:prstGeom>) <>
      ~s(</p:spPr>) <>
      ~s(</p:pic>)
  end

  defp shape_preset(:ellipse), do: "ellipse"
  defp shape_preset(:diamond), do: "diamond"
  defp shape_preset(:round_rect), do: "roundRect"
  defp shape_preset(:star5), do: "star5"
  defp shape_preset(:star6), do: "star6"
  defp shape_preset(:star8), do: "star8"
  defp shape_preset(:heart), do: "heart"
  defp shape_preset(:triangle), do: "triangle"
  defp shape_preset(:hexagon), do: "hexagon"
  defp shape_preset(:octagon), do: "octagon"
  defp shape_preset(str) when is_binary(str), do: str

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

  @default_dpi 72

  defp resolve_size(_binary, _ext, width_opt, height_opt)
       when not is_nil(width_opt) and not is_nil(height_opt) do
    {Units.to_emu(width_opt), Units.to_emu(height_opt)}
  end

  defp resolve_size(binary, ext, width_opt, height_opt) do
    if ext in ["emf", "wmf", "tiff"] do
      raise ArgumentError,
            "explicit :width and :height are required for #{String.upcase(ext)} images"
    end

    {native_w, native_h, horz_dpi, vert_dpi} = native_size(binary, ext)
    scale(width_opt, height_opt, native_w, native_h, horz_dpi, vert_dpi)
  end

  defp scale(nil, nil, native_w, native_h, horz_dpi, vert_dpi) do
    {round(914_400 * native_w / horz_dpi), round(914_400 * native_h / vert_dpi)}
  end

  defp scale(width_opt, nil, native_w, native_h, _horz_dpi, _vert_dpi) do
    w = Units.to_emu(width_opt)
    h = round(w * native_h / native_w)
    {w, h}
  end

  defp scale(nil, height_opt, native_w, native_h, _horz_dpi, _vert_dpi) do
    h = Units.to_emu(height_opt)
    w = round(h * native_w / native_h)
    {w, h}
  end

  # PNG: IHDR at offset 16 (width 4 bytes BE, height 4 bytes BE)
  # Optional pHYs chunk for DPI
  defp native_size(binary, "png") do
    <<_header::binary-size(16), width::32-big, height::32-big, _rest::binary>> = binary
    {horz_dpi, vert_dpi} = png_dpi(binary)
    {width, height, horz_dpi, vert_dpi}
  end

  # JPEG: scan for SOF marker (FF C0, FF C1, FF C2)
  defp native_size(binary, "jpeg") do
    {width, height} = jpeg_dimensions(binary, 2)
    {horz_dpi, vert_dpi} = jpeg_dpi(binary)
    {width, height, horz_dpi, vert_dpi}
  end

  # BMP: width at 18-21 (LE int32), height at 22-25 (LE int32)
  defp native_size(binary, "bmp") do
    <<_header::binary-size(18), width::32-little-signed, height::32-little-signed, _rest::binary>> =
      binary

    height = abs(height)
    {horz_dpi, vert_dpi} = bmp_dpi(binary)
    {width, height, horz_dpi, vert_dpi}
  end

  # GIF: width at 6-7 (LE uint16), height at 8-9 (LE uint16)
  defp native_size(binary, "gif") do
    <<_header::binary-size(6), width::16-little, height::16-little, _rest::binary>> = binary
    {width, height, @default_dpi, @default_dpi}
  end

  defp png_dpi(binary) do
    case :binary.match(binary, <<0x70, 0x48, 0x59, 0x73>>) do
      {pos, 4} ->
        # pHYs chunk data starts 4 bytes after the type
        data_start = pos + 4
        <<_::binary-size(data_start), ppm_x::32-big, ppm_y::32-big, unit::8, _::binary>> = binary

        if unit == 1 do
          {ppm_to_dpi(ppm_x), ppm_to_dpi(ppm_y)}
        else
          {@default_dpi, @default_dpi}
        end

      :nomatch ->
        {@default_dpi, @default_dpi}
    end
  end

  defp ppm_to_dpi(ppm), do: round(ppm / 39.3701)

  defp jpeg_dimensions(binary, offset) when offset < byte_size(binary) - 1 do
    <<_::binary-size(offset), rest::binary>> = binary

    case rest do
      <<0xFF, marker, _::binary>> when marker in [0xC0, 0xC1, 0xC2] ->
        <<_::binary-size(offset), 0xFF, _marker, _len::16, _precision::8, height::16-big,
          width::16-big, _rest2::binary>> = binary

        {width, height}

      <<0xFF, _marker, len::16-big, _::binary>> ->
        jpeg_dimensions(binary, offset + 2 + len)

      _ ->
        jpeg_dimensions(binary, offset + 1)
    end
  end

  defp jpeg_dimensions(_binary, _offset), do: {1, 1}

  defp jpeg_dpi(binary) do
    # Check for JFIF APP0 marker (FF E0)
    case :binary.match(binary, <<0xFF, 0xE0>>) do
      {pos, 2} ->
        data_start = pos + 4

        if data_start + 10 <= byte_size(binary) do
          <<_::binary-size(data_start), _jfif_header::binary-size(5), unit::8, x_density::16-big,
            y_density::16-big, _::binary>> = binary

          case unit do
            1 -> {x_density, y_density}
            2 -> {round(x_density * 2.54), round(y_density * 2.54)}
            _ -> {@default_dpi, @default_dpi}
          end
        else
          {@default_dpi, @default_dpi}
        end

      :nomatch ->
        {@default_dpi, @default_dpi}
    end
  end

  defp bmp_dpi(binary) do
    if byte_size(binary) >= 46 do
      <<_::binary-size(38), ppm_x::32-little, ppm_y::32-little, _::binary>> = binary

      if ppm_x > 0 and ppm_y > 0 do
        {ppm_to_dpi(ppm_x), ppm_to_dpi(ppm_y)}
      else
        {@default_dpi, @default_dpi}
      end
    else
      {@default_dpi, @default_dpi}
    end
  end

  defp detect_extension(<<0x89, 0x50, 0x4E, 0x47, _rest::binary>>), do: "png"
  defp detect_extension(<<0xFF, 0xD8, _rest::binary>>), do: "jpeg"
  defp detect_extension(<<0x42, 0x4D, _rest::binary>>), do: "bmp"
  defp detect_extension(<<0x47, 0x49, 0x46, _rest::binary>>), do: "gif"
  # TIFF little-endian
  defp detect_extension(<<0x49, 0x49, 0x2A, 0x00, _rest::binary>>), do: "tiff"
  # TIFF big-endian
  defp detect_extension(<<0x4D, 0x4D, 0x00, 0x2A, _rest::binary>>), do: "tiff"

  # EMF: starts with 01 00 00 00 (record type 1 = EMR_HEADER)
  defp detect_extension(<<0x01, 0x00, 0x00, 0x00, _rest::binary>> = binary)
       when byte_size(binary) >= 44 do
    <<_::binary-size(40), signature::32-little, _::binary>> = binary

    if signature == 0x464D4520 do
      "emf"
    else
      raise ArgumentError,
            "unsupported image format (expected PNG, JPEG, BMP, GIF, TIFF, EMF, or WMF)"
    end
  end

  # WMF: placeable metafile key 0xD7CDC69A (little-endian)
  defp detect_extension(<<0x9A, 0xC6, 0xCD, 0xD7, _rest::binary>>), do: "wmf"
  # WMF: standard metafile header (type 1 or 2, header size 9)
  defp detect_extension(<<type::16-little, 0x09, 0x00, _rest::binary>>)
       when type in [1, 2],
       do: "wmf"

  defp detect_extension(_binary),
    do:
      raise(
        ArgumentError,
        "unsupported image format (expected PNG, JPEG, BMP, GIF, TIFF, EMF, or WMF)"
      )
end
