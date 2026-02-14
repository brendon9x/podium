# Video Embedding

Embed video files in your presentations with `Podium.add_movie/3`. The video
appears as a clickable player that viewers can play during a slideshow.

```elixir
video_data = File.read!("quarterly_recap.mp4")

slide =
  Podium.add_movie(slide, video_data,
    x: {2, :inches}, y: {1.5, :inches},
    width: {9, :inches}, height: {5, :inches},
    mime_type: "video/mp4")
```

## Adding Video

`Podium.add_movie/3` takes the slide, video binary, and options.
All position and size options are required -- there is no auto-scaling for video.

```elixir
video_data = File.read!("demo.mp4")

slide =
  Podium.Slide.new(:title_only)
  |> Podium.set_placeholder(:title, "Product Demo")
  |> Podium.add_movie(video_data,
    x: {2.67, :inches}, y: {1.5, :inches},
    width: {8, :inches}, height: {4.5, :inches},
    mime_type: "video/mp4")

Podium.new()
|> Podium.add_slide(slide)
|> Podium.save("product_demo.pptx")
```

## Supported Formats and MIME Types

Specify the video format with the `:mime_type` option. Podium uses the MIME type
to determine the file extension stored in the .pptx package:

| MIME Type | Extension |
|-----------|-----------|
| `video/mp4` | .mp4 |
| `video/mpeg` | .mpg |
| `video/x-msvideo` | .avi |
| `video/x-ms-wmv` | .wmv |
| `video/quicktime` | .mov |
| `video/webm` | .webm |
| `video/x-flv` | .flv |
| `video/unknown` | .bin (default) |

## Poster Frames

The poster frame is the image displayed before the video plays. By default,
Podium uses a minimal 1x1 pixel placeholder. To show a meaningful preview,
pass a custom poster frame image:

```elixir
video_data = File.read!("quarterly_recap.mp4")
poster = File.read!("recap_thumbnail.png")

slide =
  Podium.add_movie(slide, video_data,
    x: {2, :inches}, y: {1.5, :inches},
    width: {9, :inches}, height: {5, :inches},
    mime_type: "video/mp4",
    poster_frame: poster)
```

Poster frames can be PNG or JPEG. The format is auto-detected from magic bytes.

## Video Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:x` | `emu_spec` | required | Horizontal position |
| `:y` | `emu_spec` | required | Vertical position |
| `:width` | `emu_spec` | required | Video player width |
| `:height` | `emu_spec` | required | Video player height |
| `:mime_type` | `String.t()` | `"video/unknown"` | Video MIME type |
| `:poster_frame` | `binary` | 1x1 PNG | Poster frame image binary |

## Media Deduplication

When you embed the same video on multiple slides, Podium stores it once in the
.pptx package. Videos are identified by SHA-1 hash of their binary content,
keeping file sizes manageable.

## Playback Behavior

Embedded videos play within PowerPoint's slideshow mode. The viewer clicks the
video frame to start playback. Podium generates the timing XML needed for
PowerPoint to recognize the embedded media.

---

For customizing slide appearance, see the [Slide Backgrounds and Speaker Notes](slide-backgrounds-and-notes.md) guide.
