defmodule Spaceboy.Utils do
  @moduledoc false

  def split(nil), do: []

  def split(path) do
    path
    |> String.split("/")
    |> Enum.filter(&(&1 != ""))
  end
end
