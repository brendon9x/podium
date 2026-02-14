defmodule Podium.Video do
  @moduledoc """
  Embedded video with MIME-based extension detection.

  Videos are embedded with a poster frame image and timing XML for playback
  control within the slide.
  """

  alias Podium.OPC.Constants
  alias Podium.Units

  defstruct [
    :media_index,
    :binary,
    :extension,
    :sha1,
    :mime_type,
    :x,
    :y,
    :width,
    :height,
    :poster_frame
  ]

  @type t :: %__MODULE__{
          media_index: pos_integer(),
          binary: binary(),
          extension: String.t(),
          sha1: String.t(),
          mime_type: String.t(),
          x: non_neg_integer(),
          y: non_neg_integer(),
          width: non_neg_integer(),
          height: non_neg_integer(),
          poster_frame: map()
        }

  # Minimal 1x1 PNG used as default poster frame (speaker icon placeholder)
  @default_poster_png <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
                        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
                        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
                        0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00,
                        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82>>

  @doc """
  Creates a new video from binary data with position and size.

  ## Options (required)
    * `:x`, `:y`, `:width`, `:height` - position and size

  ## Options (optional)
    * `:mime_type` - MIME type string (default `"video/unknown"`)
    * `:poster_frame` - poster frame image binary (default: 1x1 transparent PNG)
  """
  @spec new(binary(), pos_integer(), pos_integer(), keyword()) :: t()
  def new(binary, media_index, poster_image_index, opts) when is_binary(binary) do
    mime_type = Keyword.get(opts, :mime_type, "video/unknown")
    extension = detect_extension(mime_type)
    sha1 = :crypto.hash(:sha, binary) |> Base.encode16(case: :lower)

    poster_binary = Keyword.get(opts, :poster_frame, @default_poster_png)
    poster_ext = detect_poster_extension(poster_binary)

    %__MODULE__{
      media_index: media_index,
      binary: binary,
      extension: extension,
      sha1: sha1,
      mime_type: mime_type,
      x: Units.to_emu(Keyword.fetch!(opts, :x)),
      y: Units.to_emu(Keyword.fetch!(opts, :y)),
      width: Units.to_emu(Keyword.fetch!(opts, :width)),
      height: Units.to_emu(Keyword.fetch!(opts, :height)),
      poster_frame: %{
        binary: poster_binary,
        extension: poster_ext,
        image_index: poster_image_index
      }
    }
  end

  @doc "Returns the OPC partname for the video media file."
  @spec media_partname(t()) :: String.t()
  def media_partname(%__MODULE__{media_index: idx, extension: ext}),
    do: "ppt/media/media#{idx}.#{ext}"

  @doc "Returns the OPC partname for the poster frame image."
  @spec poster_partname(t()) :: String.t()
  def poster_partname(%__MODULE__{poster_frame: %{image_index: idx, extension: ext}}),
    do: "ppt/media/image#{idx}.#{ext}"

  @doc "Generates the `<p:pic>` XML for the video shape on a slide."
  @spec pic_xml(t(), pos_integer(), String.t(), String.t(), String.t()) :: String.t()
  def pic_xml(%__MODULE__{} = video, shape_id, video_rid, media_rid, poster_rid) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)
    ns_r = Constants.ns(:r)
    ns_p14 = Constants.ns(:p14)

    ~s(<p:pic xmlns:a="#{ns_a}" xmlns:p="#{ns_p}" xmlns:r="#{ns_r}">) <>
      ~s(<p:nvPicPr>) <>
      ~s(<p:cNvPr id="#{shape_id}" name="Video #{shape_id - 1}">) <>
      ~s(<a:hlinkClick r:id="" action="ppaction://media"/>) <>
      ~s(</p:cNvPr>) <>
      ~s(<p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>) <>
      ~s(<p:nvPr>) <>
      ~s(<a:videoFile r:link="#{video_rid}"/>) <>
      ~s(<p:extLst>) <>
      ~s(<p:ext uri="{DAA4B4D4-6D71-4841-9C94-3DE7FCFB9230}">) <>
      ~s(<p14:media xmlns:p14="#{ns_p14}" r:embed="#{media_rid}"/>) <>
      ~s(</p:ext>) <>
      ~s(</p:extLst>) <>
      ~s(</p:nvPr>) <>
      ~s(</p:nvPicPr>) <>
      ~s(<p:blipFill>) <>
      ~s(<a:blip r:embed="#{poster_rid}"/>) <>
      ~s(<a:stretch><a:fillRect/></a:stretch>) <>
      ~s(</p:blipFill>) <>
      ~s(<p:spPr>) <>
      ~s(<a:xfrm>) <>
      ~s(<a:off x="#{video.x}" y="#{video.y}"/>) <>
      ~s(<a:ext cx="#{video.width}" cy="#{video.height}"/>) <>
      ~s(</a:xfrm>) <>
      ~s(<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>) <>
      ~s(</p:spPr>) <>
      ~s(</p:pic>)
  end

  @doc "Generates the timing XML for video playback in the slide's `<p:timing>` element."
  @spec video_timing_xml(pos_integer(), pos_integer()) :: String.t()
  def video_timing_xml(shape_id, ctn_id) do
    ~s(<p:video>) <>
      ~s(<p:cMediaNode vol="80000">) <>
      ~s(<p:cTn id="#{ctn_id}" fill="hold" display="0">) <>
      ~s(<p:stCondLst><p:cond delay="indefinite"/></p:stCondLst>) <>
      ~s(</p:cTn>) <>
      ~s(<p:tgtEl><p:spTgt spid="#{shape_id}"/></p:tgtEl>) <>
      ~s(</p:cMediaNode>) <>
      ~s(</p:video>)
  end

  @doc "Maps a MIME type string to a file extension."
  @spec detect_extension(String.t()) :: String.t()
  def detect_extension("video/mp4"), do: "mp4"
  def detect_extension("video/mpeg"), do: "mpg"
  def detect_extension("video/x-msvideo"), do: "avi"
  def detect_extension("video/x-ms-wmv"), do: "wmv"
  def detect_extension("video/quicktime"), do: "mov"
  def detect_extension("video/webm"), do: "webm"
  def detect_extension("video/x-flv"), do: "flv"
  def detect_extension("video/unknown"), do: "bin"
  def detect_extension("video/" <> ext), do: ext
  def detect_extension(_), do: "bin"

  defp detect_poster_extension(<<0x89, 0x50, 0x4E, 0x47, _::binary>>), do: "png"
  defp detect_poster_extension(<<0xFF, 0xD8, _::binary>>), do: "jpeg"
  defp detect_poster_extension(_), do: "png"
end
