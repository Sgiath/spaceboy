defmodule Spaceboy.Middleware.Logger do
  @moduledoc ~S"""
  Example middleware which provides simple logging for processed request.

  Use in your `Spaceboy.Server` implementation as:

      middleware Spaceboy.Middleware.Logger

  It takes optional config `:log_level` which sets the level at which the logs
  are logged. By default it is `:debug` level.

      middleware Spaceboy.Middleware.Logger, log_level: :info

  """
  @moduledoc authors: ["Sgiath <sgiath@sgiath.dev>"]

  @behaviour Spaceboy.Middleware

  alias Spaceboy.Conn

  require Logger

  @impl Spaceboy.Middleware
  def init(opts), do: opts

  @impl Spaceboy.Middleware
  def call(%Conn{request_path: path} = conn, opts) do
    level = Keyword.get(opts, :log_level, :debug)
    Logger.log(level, path || "/")

    start = System.monotonic_time()

    Conn.register_before_send(conn, fn %Conn{header: header} = conn ->
      Logger.log(level, fn ->
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
