File.mkdir_p!("demos/output")

alias Podium.Layout
alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Title row + content row
s1 =
  Podium.Slide.new()
  |> then(fn slide ->
    grid = Layout.grid(slide)

    {title_row, grid} = Layout.row(grid, height: {20, :percent})
    [header] = Layout.cols(title_row, ["col-12"])

    {content_row, _grid} = Layout.row(grid)
    [body] = Layout.cols(content_row, ["col-12"])

    slide
    |> Podium.add_text_box(
      [[{"Grid Layout", bold: true, font_size: 36, color: "FFFFFF"}]],
      header ++ [fill: "003366", alignment: :center, anchor: :middle]
    )
    |> Podium.add_text_box(
      {:html,
       """
       <p>The grid system uses Bootstrap vocabulary to compute positions.</p>
       <p>No manual coordinate calculation required — just <b>col-N</b> specs.</p>
       <ul>
         <li>12-column grid with configurable margins and gutters</li>
         <li>Rows stack vertically with explicit or auto height</li>
         <li>Output is keyword lists passed directly to <b>add_*</b> functions</li>
       </ul>
       """},
      body ++ [font_size: 18, anchor: :middle]
    )
  end)

# Slide 2: Two-column — chart + text
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [120, 180, 150, 220], color: "4472C4")
  |> ChartData.add_series("Costs", [80, 100, 95, 130], color: "ED7D31")

s2 =
  Podium.Slide.new()
  |> then(fn slide ->
    grid = Layout.grid(slide)

    {title_row, grid} = Layout.row(grid, height: {15, :percent})
    [header] = Layout.cols(title_row, ["col-12"])

    {content_row, _grid} = Layout.row(grid)
    [left, right] = Layout.cols(content_row, ["col-8", "col-4"])

    slide
    |> Podium.add_text_box(
      [[{"Two-Column Layout", bold: true, font_size: 28, color: "003366"}]],
      header ++ [alignment: :center, anchor: :middle]
    )
    |> Podium.add_chart(
      :column_clustered,
      chart_data,
      left ++ [title: "Quarterly Performance", legend: :bottom]
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
      right ++ [fill: "E2EFDA", font_size: 14]
    )
  end)

# Slide 3: Three equal columns
s3 =
  Podium.Slide.new()
  |> then(fn slide ->
    grid = Layout.grid(slide)

    {title_row, grid} = Layout.row(grid, height: {15, :percent})
    [header] = Layout.cols(title_row, ["col-12"])

    {content_row, _grid} = Layout.row(grid)
    [c1, c2, c3] = Layout.cols(content_row, ["col-4", "col-4", "col-4"])

    slide
    |> Podium.add_text_box(
      [[{"Three Columns", bold: true, font_size: 28, color: "003366"}]],
      header ++ [alignment: :center, anchor: :middle]
    )
    |> Podium.add_text_box(
      [
        [{"Phase 1", bold: true, color: "FFFFFF", font_size: 20}],
        [{"Research & Planning", color: "FFFFFF"}]
      ],
      c1 ++ [fill: "4472C4", alignment: :center, anchor: :middle]
    )
    |> Podium.add_text_box(
      [
        [{"Phase 2", bold: true, color: "FFFFFF", font_size: 20}],
        [{"Development", color: "FFFFFF"}]
      ],
      c2 ++ [fill: "ED7D31", alignment: :center, anchor: :middle]
    )
    |> Podium.add_text_box(
      [
        [{"Phase 3", bold: true, color: "FFFFFF", font_size: 20}],
        [{"Launch & Review", color: "FFFFFF"}]
      ],
      c3 ++ [fill: "70AD47", alignment: :center, anchor: :middle]
    )
  end)

# Slide 4: Centered offset column
s4 =
  Podium.Slide.new()
  |> then(fn slide ->
    grid = Layout.grid(slide)

    {title_row, grid} = Layout.row(grid, height: {15, :percent})
    [header] = Layout.cols(title_row, ["col-12"])

    {content_row, _grid} = Layout.row(grid)
    [centered] = Layout.cols(content_row, ["col-6 offset-3"])

    slide
    |> Podium.add_text_box(
      [[{"Centered with offset-3", bold: true, font_size: 28, color: "003366"}]],
      header ++ [alignment: :center, anchor: :middle]
    )
    |> Podium.add_text_box(
      {:html,
       """
       <p style="text-align: center"><b>col-6 offset-3</b></p>
       <p style="text-align: center">This column is centered on the slide using an offset, just like Bootstrap's offset classes.</p>
       """},
      centered ++ [fill: "DAEEF3", font_size: 16, anchor: :middle]
    )
  end)

# Slide 5: Custom config — 6-column grid with large margins
s5 =
  Podium.Slide.new()
  |> then(fn slide ->
    grid = Layout.grid(slide, columns: 6, margin: {8, :percent}, gutter: {3, :percent})

    {title_row, grid} = Layout.row(grid, height: {20, :percent})
    [header] = Layout.cols(title_row, ["col-6"])

    {content_row, _grid} = Layout.row(grid)
    [left, right] = Layout.cols(content_row, ["col-4", "col-2"])

    slide
    |> Podium.add_text_box(
      [[{"Custom Grid Config", bold: true, font_size: 28, color: "FFFFFF"}]],
      header ++ [fill: "003366", alignment: :center, anchor: :middle]
    )
    |> Podium.add_text_box(
      {:html,
       """
       <p><b>6-column grid</b></p>
       <ul>
         <li>columns: 6</li>
         <li>margin: 8%</li>
         <li>gutter: 3%</li>
       </ul>
       <p>This is <b>col-4</b> in a 6-column grid.</p>
       """},
      left ++ [fill: "E2EFDA", font_size: 14]
    )
    |> Podium.add_text_box(
      [[{"col-2", bold: true, font_size: 16, color: "FFFFFF"}]],
      right ++ [fill: "4472C4", alignment: :center, anchor: :middle]
    )
  end)

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.save("demos/output/grid-layout.pptx")

IO.puts("Generated demos/output/grid-layout.pptx")
