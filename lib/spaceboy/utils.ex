defmodule Spaceboy.Utils do
  @moduledoc false

  @spec split(path :: nil | String.t()) :: [String.t()]
  def split(nil), do: []

  def split(path) do
    path
    |> String.split("/")
    |> Enum.filter(&(&1 != ""))
  end
end
