defmodule Podium.Pattern do
  @moduledoc """
  Maps pattern fill atoms to OOXML preset strings.

  All 54 OOXML pattern presets are supported for use in shape fills, line fills,
  and slide backgrounds. Common presets include `:lt_horz`, `:lt_vert`,
  `:dk_dn_diag`, `:cross`, `:diag_cross`, and percentage fills from `:pct_5`
  through `:pct_90`.

  ## Example

      # Pattern fill on a text box
      slide = Podium.add_text_box(slide, "Patterned",
        x: {1, :inches}, y: {1, :inches},
        width: {4, :inches}, height: {1, :inches},
        fill: {:pattern, :lt_horz, fg: "000000", bg: "FFFFFF"})

  See the [Shapes and Styling](shapes-and-styling.md) guide for more examples.
  """

  @doc """
  Maps pattern fill atoms to OOXML preset strings for `<a:pattFill prst="...">`.
  """
  @spec preset(atom()) :: String.t()
  def preset(:dn_diag), do: "dnDiag"
  def preset(:up_diag), do: "upDiag"
  def preset(:lt_horz), do: "ltHorz"
  def preset(:lt_vert), do: "ltVert"
  def preset(:dk_dn_diag), do: "dkDnDiag"
  def preset(:dk_up_diag), do: "dkUpDiag"
  def preset(:dk_horz), do: "dkHorz"
  def preset(:dk_vert), do: "dkVert"
  def preset(:sm_grid), do: "smGrid"
  def preset(:lg_grid), do: "lgGrid"
  def preset(:cross), do: "cross"
  def preset(:diag_cross), do: "diagCross"
  def preset(:pct_5), do: "pct5"
  def preset(:pct_10), do: "pct10"
  def preset(:pct_20), do: "pct20"
  def preset(:pct_25), do: "pct25"
  def preset(:pct_30), do: "pct30"
  def preset(:pct_40), do: "pct40"
  def preset(:pct_50), do: "pct50"
  def preset(:pct_60), do: "pct60"
  def preset(:pct_70), do: "pct70"
  def preset(:pct_75), do: "pct75"
  def preset(:pct_80), do: "pct80"
  def preset(:pct_90), do: "pct90"
  def preset(:wave), do: "wave"
  def preset(:weave), do: "weave"
  def preset(:plaid), do: "plaid"
  def preset(:sphere), do: "sphere"
  def preset(:zig_zag), do: "zigZag"
  def preset(:horz), do: "horz"
  def preset(:vert), do: "vert"
  def preset(:trellis), do: "trellis"
  def preset(:divot), do: "divot"
  def preset(:shingle), do: "shingle"
  def preset(:dot_grid), do: "dotGrid"
  def preset(:sm_check), do: "smCheck"
  def preset(:lg_check), do: "lgCheck"
  def preset(:sm_confetti), do: "smConfetti"
  def preset(:lg_confetti), do: "lgConfetti"
  def preset(:horz_brick), do: "horzBrick"
  def preset(:diag_brick), do: "diagBrick"
  def preset(:solid_dmnd), do: "solidDmnd"
  def preset(:open_dmnd), do: "openDmnd"
  def preset(:dot_dmnd), do: "dotDmnd"
  def preset(:dash_dn_diag), do: "dashDnDiag"
  def preset(:dash_up_diag), do: "dashUpDiag"
  def preset(:dash_horz), do: "dashHorz"
  def preset(:dash_vert), do: "dashVert"
  def preset(:nar_horz), do: "narHorz"
  def preset(:nar_vert), do: "narVert"
  def preset(:lt_dn_diag), do: "ltDnDiag"
  def preset(:lt_up_diag), do: "ltUpDiag"
  def preset(:wd_dn_diag), do: "wdDnDiag"
  def preset(:wd_up_diag), do: "wdUpDiag"
end
