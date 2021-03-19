defmodule Spaceboy.Utils do
  @moduledoc false

  def split(path) do
    path
    |> String.split("/")
    |> Enum.filter(fn segment -> segment != "" end)
  end
end
