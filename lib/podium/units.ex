defmodule Podium.Units do
  @moduledoc false

  @emu_per_inch 914_400
  @emu_per_cm 360_000
  @emu_per_pt 12_700

  @doc """
  Converts a value with unit to EMU (English Metric Units).

  ## Examples

      iex> Podium.Units.to_emu({1, :inches})
      914400

      iex> Podium.Units.to_emu({2.54, :cm})
      914400

      iex> Podium.Units.to_emu({72, :pt})
      914400

      iex> Podium.Units.to_emu(914400)
      914400
  """
  def to_emu({value, :inches}), do: round(value * @emu_per_inch)
  def to_emu({value, :cm}), do: round(value * @emu_per_cm)
  def to_emu({value, :pt}), do: round(value * @emu_per_pt)
  def to_emu(emu) when is_integer(emu), do: emu
end
