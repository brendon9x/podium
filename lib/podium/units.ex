defmodule Podium.Units do
  @moduledoc """
  EMU (English Metric Units) conversion utilities.

  OOXML uses EMU as its base unit for all measurements. This module converts
  from human-friendly units to EMU.

    * 1 inch = 914,400 EMU
    * 1 cm = 360,000 EMU
    * 1 point = 12,700 EMU

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

  @emu_per_inch 914_400
  @emu_per_cm 360_000
  @emu_per_pt 12_700

  @doc """
  Converts a value with unit to EMU (English Metric Units).

  Note: `{value, :percent}` is intentionally not handled here — percent values
  require a reference dimension and must be resolved via `resolve_percent/2`
  before reaching this function.

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
  @spec to_emu(Podium.dimension()) :: non_neg_integer()
  def to_emu({value, :inches}), do: round(value * @emu_per_inch)
  def to_emu({value, :cm}), do: round(value * @emu_per_cm)
  def to_emu({value, :pt}), do: round(value * @emu_per_pt)
  def to_emu(emu) when is_integer(emu), do: emu

  @doc """
  Resolves a percent dimension against a reference EMU value.

  ## Examples

      iex> Podium.Units.resolve_percent({50, :percent}, 12_192_000)
      6096000

      iex> Podium.Units.resolve_percent({100, :percent}, 6_858_000)
      6858000
  """
  @spec resolve_percent({number(), :percent}, non_neg_integer()) :: non_neg_integer()
  def resolve_percent({value, :percent}, reference_emu) do
    round(value / 100 * reference_emu)
  end
end
