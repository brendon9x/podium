defmodule Podium.XML.Builder do
  @moduledoc false

  @doc """
  Returns the XML declaration header.
  """
  def xml_declaration do
    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>)
  end

  @doc """
  Escapes special characters for XML text content.
  """
  def escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  def escape(other), do: to_string(other)
end
