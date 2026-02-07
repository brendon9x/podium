defmodule Podium.PatternTest do
  use ExUnit.Case, async: true

  alias Podium.Pattern

  @all_presets %{
    # Original 24 presets
    dn_diag: "dnDiag",
    up_diag: "upDiag",
    lt_horz: "ltHorz",
    lt_vert: "ltVert",
    dk_dn_diag: "dkDnDiag",
    dk_up_diag: "dkUpDiag",
    dk_horz: "dkHorz",
    dk_vert: "dkVert",
    sm_grid: "smGrid",
    lg_grid: "lgGrid",
    cross: "cross",
    diag_cross: "diagCross",
    pct_5: "pct5",
    pct_10: "pct10",
    pct_20: "pct20",
    pct_25: "pct25",
    pct_30: "pct30",
    pct_40: "pct40",
    pct_50: "pct50",
    pct_60: "pct60",
    pct_70: "pct70",
    pct_75: "pct75",
    pct_80: "pct80",
    pct_90: "pct90",
    # 30 new presets
    wave: "wave",
    weave: "weave",
    plaid: "plaid",
    sphere: "sphere",
    zig_zag: "zigZag",
    horz: "horz",
    vert: "vert",
    trellis: "trellis",
    divot: "divot",
    shingle: "shingle",
    dot_grid: "dotGrid",
    sm_check: "smCheck",
    lg_check: "lgCheck",
    sm_confetti: "smConfetti",
    lg_confetti: "lgConfetti",
    horz_brick: "horzBrick",
    diag_brick: "diagBrick",
    solid_dmnd: "solidDmnd",
    open_dmnd: "openDmnd",
    dot_dmnd: "dotDmnd",
    dash_dn_diag: "dashDnDiag",
    dash_up_diag: "dashUpDiag",
    dash_horz: "dashHorz",
    dash_vert: "dashVert",
    nar_horz: "narHorz",
    nar_vert: "narVert",
    lt_dn_diag: "ltDnDiag",
    lt_up_diag: "ltUpDiag",
    wd_dn_diag: "wdDnDiag",
    wd_up_diag: "wdUpDiag"
  }

  describe "preset/1" do
    test "all 54 presets map to correct OOXML values" do
      for {atom, expected} <- @all_presets do
        assert Pattern.preset(atom) == expected,
               "expected preset(#{inspect(atom)}) to return #{inspect(expected)}"
      end
    end

    test "total preset count is 54" do
      assert map_size(@all_presets) == 54
    end
  end
end
