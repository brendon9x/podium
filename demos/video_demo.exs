# Video Embedding Demo
# Demonstrates embedding video files with poster frames
# 16:9 slide = 13.33" x 7.5"

video_binary = File.read!(Path.join(__DIR__, "demo.mp4"))
poster_png = File.read!(Path.join(__DIR__, "poster_frame.png"))

prs = Podium.new(title: "Video Demo", author: "Podium")

# --- Slide 1: Video with poster frame ---
{prs, slide1} = Podium.add_slide(prs, layout: :title_only)
slide1 = Podium.set_placeholder(slide1, :title, "Video Embedding Demo")

{prs, slide1} =
  Podium.add_movie(prs, slide1, video_binary,
    x: {2.67, :inches},
    y: {1.5, :inches},
    width: {8, :inches},
    height: {4.5, :inches},
    mime_type: "video/mp4",
    poster_frame: poster_png
  )

slide1 =
  Podium.add_text_box(
    slide1,
    "Click play to watch the embedded video",
    x: {2.67, :inches},
    y: {6.2, :inches},
    width: {8, :inches},
    height: {0.5, :inches}
  )

prs = Podium.put_slide(prs, slide1)

# --- Slide 2: Same video reused (dedup) with custom poster ---
{prs, slide2} = Podium.add_slide(prs, layout: :title_only)
slide2 = Podium.set_placeholder(slide2, :title, "Same Video, Deduped")

{prs, slide2} =
  Podium.add_movie(prs, slide2, video_binary,
    x: {1.67, :inches},
    y: {1.5, :inches},
    width: {10, :inches},
    height: {5.5, :inches},
    mime_type: "video/mp4",
    poster_frame: poster_png
  )

prs = Podium.put_slide(prs, slide2)

Podium.save(prs, "video_demo.pptx")
IO.puts("Saved video_demo.pptx")
