defmodule Spaceboy.Middleware.RequestId do
  @moduledoc ~S"""
  A plug for generating a unique request id for each request.

  The generated request id will be in the format
  "uq8hs30oafhj5vve8ji5pmp7mtopc08f".

  The request id is added to the Logger metadata as `:request_id` and the conn
  struct. To see the request id in your log output, configure your logger
  backends to include the `:request_id` metadata:

      config :logger, :console, metadata: [:request_id]

  It is recommended to include this metadata configuration in your production
  configuration file.

  You can also access the `request_id` programmatically by calling
  `Logger.metadata[:request_id]`.

  To use this middleware, just plug it into the desired server:

      middleware Spaceboy.Middleware.RequestId

  """

  @behaviour Spaceboy.Middleware

  alias Spaceboy.Conn

  @impl Spaceboy.Middleware
  def init(opts), do: opts

  @impl Spaceboy.Middleware
  def call(conn, _opts) do
    request_id = generate_request_id()

    Logger.metadata(request_id: request_id)
    %Conn{conn | request_id: request_id}
  end

  defp generate_request_id do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    Base.url_encode64(binary)
  end
end
