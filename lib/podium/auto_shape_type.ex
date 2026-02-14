defmodule Podium.AutoShapeType do
  @moduledoc """
  Maps auto shape preset atoms to OOXML preset geometry strings.

  Podium supports all 187 preset geometries from the OOXML specification,
  including rectangles, arrows, stars, callouts, and flowchart symbols.

  Use `all_types/0` to get the full sorted list of available shape presets,
  and `prst/1` to look up the OOXML preset string for a given atom.

  See the [Shapes and Styling](shapes-and-styling.md) guide for usage examples.
  """

  # Map of atom keys to {prst_string, basename} tuples.
  # Sourced from python-pptx MSO_AUTO_SHAPE_TYPE enum (187 entries).
  @shape_types %{
    action_button_back_or_previous:
      {"actionButtonBackPrevious", "Action Button: Back or Previous"},
    action_button_beginning: {"actionButtonBeginning", "Action Button: Beginning"},
    action_button_custom: {"actionButtonBlank", "Action Button: Custom"},
    action_button_document: {"actionButtonDocument", "Action Button: Document"},
    action_button_end: {"actionButtonEnd", "Action Button: End"},
    action_button_forward_or_next: {"actionButtonForwardNext", "Action Button: Forward or Next"},
    action_button_help: {"actionButtonHelp", "Action Button: Help"},
    action_button_home: {"actionButtonHome", "Action Button: Home"},
    action_button_information: {"actionButtonInformation", "Action Button: Information"},
    action_button_movie: {"actionButtonMovie", "Action Button: Movie"},
    action_button_return: {"actionButtonReturn", "Action Button: Return"},
    action_button_sound: {"actionButtonSound", "Action Button: Sound"},
    arc: {"arc", "Arc"},
    balloon: {"wedgeRoundRectCallout", "Rounded Rectangular Callout"},
    bent_arrow: {"bentArrow", "Bent Arrow"},
    bent_up_arrow: {"bentUpArrow", "Bent Up Arrow"},
    bevel: {"bevel", "Bevel"},
    block_arc: {"blockArc", "Block Arc"},
    can: {"can", "Can"},
    chart_plus: {"chartPlus", "Chart Plus"},
    chart_star: {"chartStar", "Chart Star"},
    chart_x: {"chartX", "Chart X"},
    chevron: {"chevron", "Chevron"},
    chord: {"chord", "Chord"},
    circular_arrow: {"circularArrow", "Circular Arrow"},
    cloud: {"cloud", "Cloud"},
    cloud_callout: {"cloudCallout", "Cloud Callout"},
    corner: {"corner", "Corner"},
    corner_tabs: {"cornerTabs", "Corner Tabs"},
    cross: {"plus", "Cross"},
    cube: {"cube", "Cube"},
    curved_down_arrow: {"curvedDownArrow", "Curved Down Arrow"},
    curved_down_ribbon: {"ellipseRibbon", "Curved Down Ribbon"},
    curved_left_arrow: {"curvedLeftArrow", "Curved Left Arrow"},
    curved_right_arrow: {"curvedRightArrow", "Curved Right Arrow"},
    curved_up_arrow: {"curvedUpArrow", "Curved Up Arrow"},
    curved_up_ribbon: {"ellipseRibbon2", "Curved Up Ribbon"},
    decagon: {"decagon", "Decagon"},
    diagonal_stripe: {"diagStripe", "Diagonal Stripe"},
    diamond: {"diamond", "Diamond"},
    dodecagon: {"dodecagon", "Dodecagon"},
    donut: {"donut", "Donut"},
    double_brace: {"bracePair", "Double Brace"},
    double_bracket: {"bracketPair", "Double Bracket"},
    double_wave: {"doubleWave", "Double Wave"},
    down_arrow: {"downArrow", "Down Arrow"},
    down_arrow_callout: {"downArrowCallout", "Down Arrow Callout"},
    down_ribbon: {"ribbon", "Down Ribbon"},
    explosion1: {"irregularSeal1", "Explosion 1"},
    explosion2: {"irregularSeal2", "Explosion 2"},
    flowchart_alternate_process: {"flowChartAlternateProcess", "Flowchart: Alternate Process"},
    flowchart_card: {"flowChartPunchedCard", "Flowchart: Card"},
    flowchart_collate: {"flowChartCollate", "Flowchart: Collate"},
    flowchart_connector: {"flowChartConnector", "Flowchart: Connector"},
    flowchart_data: {"flowChartInputOutput", "Flowchart: Data"},
    flowchart_decision: {"flowChartDecision", "Flowchart: Decision"},
    flowchart_delay: {"flowChartDelay", "Flowchart: Delay"},
    flowchart_direct_access_storage:
      {"flowChartMagneticDrum", "Flowchart: Direct Access Storage"},
    flowchart_display: {"flowChartDisplay", "Flowchart: Display"},
    flowchart_document: {"flowChartDocument", "Flowchart: Document"},
    flowchart_extract: {"flowChartExtract", "Flowchart: Extract"},
    flowchart_internal_storage: {"flowChartInternalStorage", "Flowchart: Internal Storage"},
    flowchart_magnetic_disk: {"flowChartMagneticDisk", "Flowchart: Magnetic Disk"},
    flowchart_manual_input: {"flowChartManualInput", "Flowchart: Manual Input"},
    flowchart_manual_operation: {"flowChartManualOperation", "Flowchart: Manual Operation"},
    flowchart_merge: {"flowChartMerge", "Flowchart: Merge"},
    flowchart_multidocument: {"flowChartMultidocument", "Flowchart: Multidocument"},
    flowchart_offline_storage: {"flowChartOfflineStorage", "Flowchart: Offline Storage"},
    flowchart_offpage_connector: {"flowChartOffpageConnector", "Flowchart: Off-page Connector"},
    flowchart_or: {"flowChartOr", "Flowchart: Or"},
    flowchart_predefined_process: {"flowChartPredefinedProcess", "Flowchart: Predefined Process"},
    flowchart_preparation: {"flowChartPreparation", "Flowchart: Preparation"},
    flowchart_process: {"flowChartProcess", "Flowchart: Process"},
    flowchart_punched_tape: {"flowChartPunchedTape", "Flowchart: Punched Tape"},
    flowchart_sequential_access_storage:
      {"flowChartMagneticTape", "Flowchart: Sequential Access Storage"},
    flowchart_sort: {"flowChartSort", "Flowchart: Sort"},
    flowchart_stored_data: {"flowChartOnlineStorage", "Flowchart: Stored Data"},
    flowchart_summing_junction: {"flowChartSummingJunction", "Flowchart: Summing Junction"},
    flowchart_terminator: {"flowChartTerminator", "Flowchart: Terminator"},
    folded_corner: {"foldedCorner", "Folded Corner"},
    frame: {"frame", "Frame"},
    funnel: {"funnel", "Funnel"},
    gear_6: {"gear6", "Gear 6"},
    gear_9: {"gear9", "Gear 9"},
    half_frame: {"halfFrame", "Half Frame"},
    heart: {"heart", "Heart"},
    heptagon: {"heptagon", "Heptagon"},
    hexagon: {"hexagon", "Hexagon"},
    horizontal_scroll: {"horizontalScroll", "Horizontal Scroll"},
    isosceles_triangle: {"triangle", "Isosceles Triangle"},
    left_arrow: {"leftArrow", "Left Arrow"},
    left_arrow_callout: {"leftArrowCallout", "Left Arrow Callout"},
    left_brace: {"leftBrace", "Left Brace"},
    left_bracket: {"leftBracket", "Left Bracket"},
    left_circular_arrow: {"leftCircularArrow", "Left Circular Arrow"},
    left_right_arrow: {"leftRightArrow", "Left Right Arrow"},
    left_right_arrow_callout: {"leftRightArrowCallout", "Left Right Arrow Callout"},
    left_right_circular_arrow: {"leftRightCircularArrow", "Left Right Circular Arrow"},
    left_right_ribbon: {"leftRightRibbon", "Left Right Ribbon"},
    left_right_up_arrow: {"leftRightUpArrow", "Left Right Up Arrow"},
    left_up_arrow: {"leftUpArrow", "Left Up Arrow"},
    lightning_bolt: {"lightningBolt", "Lightning Bolt"},
    line_callout_1: {"borderCallout1", "Line Callout 1"},
    line_callout_1_accent_bar: {"accentCallout1", "Line Callout 1 Accent Bar"},
    line_callout_1_border_and_accent_bar:
      {"accentBorderCallout1", "Line Callout 1 Border and Accent Bar"},
    line_callout_1_no_border: {"callout1", "Line Callout 1 No Border"},
    line_callout_2: {"borderCallout2", "Line Callout 2"},
    line_callout_2_accent_bar: {"accentCallout2", "Line Callout 2 Accent Bar"},
    line_callout_2_border_and_accent_bar:
      {"accentBorderCallout2", "Line Callout 2 Border and Accent Bar"},
    line_callout_2_no_border: {"callout2", "Line Callout 2 No Border"},
    line_callout_3: {"borderCallout3", "Line Callout 3"},
    line_callout_3_accent_bar: {"accentCallout3", "Line Callout 3 Accent Bar"},
    line_callout_3_border_and_accent_bar:
      {"accentBorderCallout3", "Line Callout 3 Border and Accent Bar"},
    line_callout_3_no_border: {"callout3", "Line Callout 3 No Border"},
    line_callout_4: {"borderCallout3", "Line Callout 4"},
    line_callout_4_accent_bar: {"accentCallout3", "Line Callout 4 Accent Bar"},
    line_callout_4_border_and_accent_bar:
      {"accentBorderCallout3", "Line Callout 4 Border and Accent Bar"},
    line_callout_4_no_border: {"callout3", "Line Callout 4 No Border"},
    line_inverse: {"lineInv", "Line Inverse"},
    math_divide: {"mathDivide", "Division"},
    math_equal: {"mathEqual", "Equal"},
    math_minus: {"mathMinus", "Minus"},
    math_multiply: {"mathMultiply", "Multiply"},
    math_not_equal: {"mathNotEqual", "Not Equal"},
    math_plus: {"mathPlus", "Plus"},
    moon: {"moon", "Moon"},
    non_isosceles_trapezoid: {"nonIsoscelesTrapezoid", "Non-isosceles Trapezoid"},
    notched_right_arrow: {"notchedRightArrow", "Notched Right Arrow"},
    no_symbol: {"noSmoking", "No Symbol"},
    octagon: {"octagon", "Octagon"},
    oval: {"ellipse", "Oval"},
    oval_callout: {"wedgeEllipseCallout", "Oval Callout"},
    parallelogram: {"parallelogram", "Parallelogram"},
    pentagon: {"homePlate", "Pentagon"},
    pie: {"pie", "Pie"},
    pie_wedge: {"pieWedge", "Pie Wedge"},
    plaque: {"plaque", "Plaque"},
    plaque_tabs: {"plaqueTabs", "Plaque Tabs"},
    quad_arrow: {"quadArrow", "Quad Arrow"},
    quad_arrow_callout: {"quadArrowCallout", "Quad Arrow Callout"},
    rectangle: {"rect", "Rectangle"},
    rectangular_callout: {"wedgeRectCallout", "Rectangular Callout"},
    regular_pentagon: {"pentagon", "Regular Pentagon"},
    right_arrow: {"rightArrow", "Right Arrow"},
    right_arrow_callout: {"rightArrowCallout", "Right Arrow Callout"},
    right_brace: {"rightBrace", "Right Brace"},
    right_bracket: {"rightBracket", "Right Bracket"},
    right_triangle: {"rtTriangle", "Right Triangle"},
    rounded_rectangle: {"roundRect", "Rounded Rectangle"},
    rounded_rectangular_callout: {"wedgeRoundRectCallout", "Rounded Rectangular Callout"},
    round_1_rectangle: {"round1Rect", "Round Single Corner Rectangle"},
    round_2_diag_rectangle: {"round2DiagRect", "Round Diagonal Corner Rectangle"},
    round_2_same_rectangle: {"round2SameRect", "Round Same Side Corner Rectangle"},
    smiley_face: {"smileyFace", "Smiley Face"},
    snip_1_rectangle: {"snip1Rect", "Snip Single Corner Rectangle"},
    snip_2_diag_rectangle: {"snip2DiagRect", "Snip Diagonal Corner Rectangle"},
    snip_2_same_rectangle: {"snip2SameRect", "Snip Same Side Corner Rectangle"},
    snip_round_rectangle: {"snipRoundRect", "Snip and Round Single Corner Rectangle"},
    square_tabs: {"squareTabs", "Square Tabs"},
    star_10_point: {"star10", "10-Point Star"},
    star_12_point: {"star12", "12-Point Star"},
    star_16_point: {"star16", "16-Point Star"},
    star_24_point: {"star24", "24-Point Star"},
    star_32_point: {"star32", "32-Point Star"},
    star_4_point: {"star4", "4-Point Star"},
    star_5_point: {"star5", "5-Point Star"},
    star_6_point: {"star6", "6-Point Star"},
    star_7_point: {"star7", "7-Point Star"},
    star_8_point: {"star8", "8-Point Star"},
    striped_right_arrow: {"stripedRightArrow", "Striped Right Arrow"},
    sun: {"sun", "Sun"},
    swoosh_arrow: {"swooshArrow", "Swoosh Arrow"},
    tear: {"teardrop", "Teardrop"},
    trapezoid: {"trapezoid", "Trapezoid"},
    up_arrow: {"upArrow", "Up Arrow"},
    up_arrow_callout: {"upArrowCallout", "Up Arrow Callout"},
    up_down_arrow: {"upDownArrow", "Up Down Arrow"},
    up_down_arrow_callout: {"upDownArrowCallout", "Up Down Arrow Callout"},
    up_ribbon: {"ribbon2", "Up Ribbon"},
    u_turn_arrow: {"uturnArrow", "U-Turn Arrow"},
    vertical_scroll: {"verticalScroll", "Vertical Scroll"},
    wave: {"wave", "Wave"}
  }

  @doc """
  Looks up the OOXML preset string and display name for a shape type atom.

  Returns a `{prst_string, basename}` tuple. Raises `ArgumentError` if the
  preset is not recognized.
  """
  @spec lookup(atom()) :: {String.t(), String.t()}
  def lookup(preset) when is_atom(preset) do
    case Map.get(@shape_types, preset) do
      nil ->
        raise ArgumentError,
              "unknown auto shape type #{inspect(preset)}. " <>
                "See Podium.AutoShapeType.all_types/0 for available types."

      result ->
        result
    end
  end

  @doc "Returns the OOXML preset geometry string for a shape type atom."
  @spec prst(atom()) :: String.t()
  def prst(preset) when is_atom(preset) do
    {prst_val, _basename} = lookup(preset)
    prst_val
  end

  @doc "Returns the display name for a shape type atom."
  @spec basename(atom()) :: String.t()
  def basename(preset) when is_atom(preset) do
    {_prst_val, basename_val} = lookup(preset)
    basename_val
  end

  @doc "Returns a sorted list of all available shape type atoms."
  @spec all_types() :: [atom()]
  def all_types, do: Map.keys(@shape_types) |> Enum.sort()
end
