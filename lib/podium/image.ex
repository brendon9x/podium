defmodule Podium.Image do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.Units

  defstruct [
    :image_index,
    :binary,
    :extension,
    :x,
    :y,
    :width,
    :height
  ]

  @doc """
  Creates a new image from binary data and position options.
  Extension is auto-detected from magic bytes.
  """
  def new(binary, image_index, opts) when is_binary(binary) do
    extension = detect_extension(binary)

    %__MODULE__{
      image_index: image_index,
      binary: binary,
      extension: extension,
      x: Units.to_emu(Keyword.fetch!(opts, :x)),
      y: Units.to_emu(Keyword.fetch!(opts, :y)),
      width: Units.to_emu(Keyword.fetch!(opts, :width)),
      height: Units.to_emu(Keyword.fetch!(opts, :height))
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

    ~s(<p:pic xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvPicPr>) <>
      ~s(<p:cNvPr id="#{shape_id}" name="Image #{image.image_index}"/>) <>
      ~s(<p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvPicPr>) <>
      ~s(<p:blipFill>) <>
      ~s(<a:blip r:embed="#{r_id}"/>) <>
      ~s(<a:stretch><a:fillRect/></a:stretch>) <>
      ~s(</p:blipFill>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm>) <>
      ~s(<a:off x="#{image.x}" y="#{image.y}"/>) <>
      ~s(<a:ext cx="#{image.width}" cy="#{image.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>) <>
      ~s(</p:spPr>) <>
      ~s(</p:pic>)
  end

  defp detect_extension(<<0x89, 0x50, 0x4E, 0x47, _rest::binary>>), do: "png"
  defp detect_extension(<<0xFF, 0xD8, _rest::binary>>), do: "jpeg"

  defp detect_extension(_binary),
    do: raise(ArgumentError, "unsupported image format (expected PNG or JPEG)")
end
