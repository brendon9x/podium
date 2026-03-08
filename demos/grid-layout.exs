File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Title row + content row
s1 =
  Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[20%_auto] p-[5%] gap-[2%]")
  |> Podium.add_text_box(
    [[{"Grid Layout", bold: true, font_size: 36, color: "FFFFFF"}]],
    style: "row-1 col-span-12",
    fill: "003366",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box(
    {:html,
     """
     <p>The grid system uses Tailwind CSS classes to compute positions.</p>
     <p>No manual coordinate calculation required — just <b>row-N col-span-N</b> classes.</p>
     <ul>
       <li>12-column grid with configurable padding and gaps</li>
       <li>Row heights via <b>grid-rows-[...]</b> template</li>
       <li>Grid config on the slide, placement inline on elements</li>
     </ul>
     """},
    style: "row-2 col-span-12",
    font_size: 18,
    anchor: :middle
  )

# Slide 2: Two-column — chart + text
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [120, 180, 150, 220], color: "4472C4")
  |> ChartData.add_series("Costs", [80, 100, 95, 130], color: "ED7D31")

s2 =
  Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")
  |> Podium.add_text_box(
    [[{"Two-Column Layout", bold: true, font_size: 28, color: "003366"}]],
    style: "row-1 col-span-12",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_chart(
    :column_clustered,
    chart_data,
    style: "row-2 col-span-8",
    title: "Quarterly Performance",
    legend: :bottom
  )
  |> Podium.add_text_box(
    {:html,
     """
     <p><b>Key Insights</b></p>
     <ul>
       <li>Revenue grew <b>83%</b> from Q1 to Q4</li>
       <li>Costs increased at a slower rate</li>
       <li>Margin expanded each quarter</li>
     </ul>
     """},
    style: "row-2 col-span-4",
    fill: "E2EFDA",
    font_size: 14
  )

# Slide 3: Three equal columns
s3 =
  Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")
  |> Podium.add_text_box(
    [[{"Three Columns", bold: true, font_size: 28, color: "003366"}]],
    style: "row-1 col-span-12",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box(
    [
      [{"Phase 1", bold: true, color: "FFFFFF", font_size: 20}],
      [{"Research & Planning", color: "FFFFFF"}]
    ],
    style: "row-2 col-span-4",
    fill: "4472C4",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box(
    [
      [{"Phase 2", bold: true, color: "FFFFFF", font_size: 20}],
      [{"Development", color: "FFFFFF"}]
    ],
    style: "row-2 col-span-4",
    fill: "ED7D31",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box(
    [
      [{"Phase 3", bold: true, color: "FFFFFF", font_size: 20}],
      [{"Launch & Review", color: "FFFFFF"}]
    ],
    style: "row-2 col-span-4",
    fill: "70AD47",
    alignment: :center,
    anchor: :middle
  )

# Slide 4: Centered column with col-start
s4 =
  Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")
  |> Podium.add_text_box(
    [[{"Centered with col-start-4", bold: true, font_size: 28, color: "003366"}]],
    style: "row-1 col-span-12",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box(
    {:html,
     """
     <p style="text-align: center"><b>col-span-6 col-start-4</b></p>
     <p style="text-align: center">This column is centered on the slide using col-start, similar to Tailwind's col-start utility.</p>
     """},
    style: "row-2 col-span-6 col-start-4",
    fill: "DAEEF3",
    font_size: 16,
    anchor: :middle
  )

# Slide 5: Custom config — 6-column grid with large padding
s5 =
  Podium.Slide.new(style: "grid grid-cols-6 grid-rows-[20%_auto] p-[8%] gap-[3%]")
  |> Podium.add_text_box(
    [[{"Custom Grid Config", bold: true, font_size: 28, color: "FFFFFF"}]],
    style: "row-1 col-span-6",
    fill: "003366",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box(
    {:html,
     """
     <p><b>6-column grid</b></p>
     <ul>
       <li>grid-cols-6</li>
       <li>p-[8%]</li>
       <li>gap-[3%]</li>
     </ul>
     <p>This is <b>col-span-4</b> in a 6-column grid.</p>
     """},
    style: "row-2 col-span-4",
    fill: "E2EFDA",
    font_size: 14
  )
  |> Podium.add_text_box(
    [[{"col-span-2", bold: true, font_size: 16, color: "FFFFFF"}]],
    style: "row-2 col-span-2",
    fill: "4472C4",
    alignment: :center,
    anchor: :middle
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.save("demos/output/grid-layout.pptx")

IO.puts("Generated demos/output/grid-layout.pptx")
