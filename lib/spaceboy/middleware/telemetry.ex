defmodule Spaceboy.Middleware.Telemetry do
  @moduledoc ~S"""
  A plug to instrument the server with `:telemetry` events.

  When plugged, the event prefix is a required option:

      middleware Spaceboy.Middleware.Telemetry, event_prefix: [:my, :server]

  In the example above, two events will be emitted:

    * `[:my, :server, :start]` - emitted when the plug is invoked.
      The event carries the `system_time` as measurement. The metadata
      is the whole `Spaceboy.Conn` under the `:conn` key and any leftover
      options given to the plug under `:options`.

    * `[:my, :server, :stop]` - emitted right before the request is sent.
      The event carries a single measurement, `:duration`,  which is the
      monotonic time difference between the stop and start events.
      It has the same metadata as the start event, except the connection
      has been updated.

  Note this plug measures the time between its invocation until a response
  is sent. The `:stop` event is not guaranteed to be emitted in all error
  cases, so this middleware cannot be used as a Telemetry span.

  ## Time unit

  The `:duration` measurements are presented in the `:native` time unit.
  You can read more about it in the docs for `System.convert_time_unit/3`.
  """

  @behaviour Spaceboy.Middleware

  @impl Spaceboy.Middleware
  def init(opts) do
    {event_prefix, opts} = Keyword.pop(opts, :event_prefix)

    unless event_prefix do
      raise ArgumentError, ":event_prefix is required"
    end

    ensure_valid_event_prefix!(event_prefix)
    start_event = event_prefix ++ [:start]
    stop_event = event_prefix ++ [:stop]
    {start_event, stop_event, opts}
  end

  @impl Spaceboy.Middleware
  def call(conn, {start_event, stop_event, opts}) do
    start_time = System.monotonic_time()
    metadata = %{conn: conn, options: opts}
    :telemetry.execute(start_event, %{system_time: System.system_time()}, metadata)

    Spaceboy.Conn.register_before_send(conn, fn conn ->
      duration = System.monotonic_time() - start_time
      :telemetry.execute(stop_event, %{duration: duration}, %{conn: conn, options: opts})
      conn
    end)
  end

  defp ensure_valid_event_prefix!(event_prefix) do
    if is_list(event_prefix) && Enum.all?(event_prefix, &is_atom/1) do
      :ok
    else
      raise ArgumentError,
            "expected :event_prefix to be a list of atoms, got: #{inspect(event_prefix)}"
    end
  end
end
