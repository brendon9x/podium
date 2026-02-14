defmodule Podium.XML.Builder do
  @moduledoc """
  XML declaration and character escaping utilities.

  Provides the standard XML declaration header and escapes special characters
  (`&`, `<`, `>`, `"`, `'`) in text content for safe XML embedding.
  """

  @doc """
  Returns the XML declaration header.
  """
  @spec xml_declaration() :: String.t()
  def xml_declaration do
    ~s(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>)
  end

  @doc """
  Escapes special characters for XML text content.
  """
  @spec escape(String.t() | term()) :: String.t()
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
