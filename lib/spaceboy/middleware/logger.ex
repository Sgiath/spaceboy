defmodule Spaceboy.Middleware.Logger do
  @moduledoc false

  @behaviour Spaceboy.Middleware

  alias Spaceboy.Conn

  require Logger

  @impl Spaceboy.Middleware
  def init(_opts), do: []

  @impl Spaceboy.Middleware
  def call(%Conn{} = conn, _opts) do
    start = System.monotonic_time()

    Conn.register_before_send(conn, fn %Conn{header: header} = conn ->
      Logger.debug(fn ->
        stop = System.monotonic_time()
        diff = System.convert_time_unit(stop - start, :native, :microsecond)

        ["Sent ", Integer.to_string(header.code), " in ", formated_diff(diff)]
      end)

      conn
    end)
  end

  defp formated_diff(diff) when diff > 1000, do: [diff |> div(1000) |> Integer.to_string(), "ms"]
  defp formated_diff(diff), do: [Integer.to_string(diff), "µs"]
end
