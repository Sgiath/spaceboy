defmodule Spaceboy.Utils do
  @moduledoc false

  def split(path) do
    path
    |> String.split("/")
    |> Enum.filter(&(&1 != ""))
  end

  def format_bind(addr) when is_binary(addr) do
    {:ok, addr} =
      addr
      |> String.to_charlist()
      |> :inet.parse_address()

    addr
  end

  def format_bind(addr), do: addr
end
