defmodule Spaceboy.Robots do
  @moduledoc ~S"""
  Controller handling robots.txt file generation

  You are not supposed to use it directly but with `Spaceboy.Router.robots/1`
  macro which nicely wraps its functionality.
  """
  @moduledoc authors: ["Sgiath <sgiath@sgiath.dev>"]

  alias Spaceboy.Conn
  alias Spaceboy.Controller

  @doc ~S"""
  Render /robots.txt file
  """
  @spec render(conn :: Conn.t(), paths :: list(String.t())) :: Conn.t()
  def render(%Conn{} = conn, paths \\ []) do
    response = """
    User-agent: *
    #{disallowed(paths)}
    """

    Controller.text(conn, response)
  end

  defp disallowed(paths) do
    paths
    |> Enum.map(&"Disallow: #{&1}")
    |> Enum.join("\n")
  end
end
