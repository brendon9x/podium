defmodule Podium.UnitsTest do
  use ExUnit.Case, async: true

  alias Podium.Units

  describe "to_emu/1" do
    test "converts inches" do
      assert Units.to_emu({1, :inches}) == 914_400
    end

    test "converts cm" do
      assert Units.to_emu({2.54, :cm}) == 914_400
    end

    test "converts pt" do
      assert Units.to_emu({72, :pt}) == 914_400
    end

    test "passes through raw EMU integers" do
      assert Units.to_emu(914_400) == 914_400
    end

    test "raises FunctionClauseError for percent (percent must be resolved before to_emu)" do
      assert_raise FunctionClauseError, fn ->
        Units.to_emu({50, :percent})
      end
    end
  end

  describe "resolve_percent/2" do
    test "50% of slide width" do
      assert Units.resolve_percent({50, :percent}, 12_192_000) == 6_096_000
    end

    test "100% returns the reference value" do
      assert Units.resolve_percent({100, :percent}, 6_858_000) == 6_858_000
    end

    test "0% returns 0" do
      assert Units.resolve_percent({0, :percent}, 12_192_000) == 0
    end

    test "fractional percent rounds correctly" do
      assert Units.resolve_percent({33.33, :percent}, 12_192_000) ==
               round(33.33 / 100 * 12_192_000)
    end
  end
end
