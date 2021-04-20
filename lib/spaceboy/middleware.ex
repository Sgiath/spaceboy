defmodule Spaceboy.Middleware do
  @moduledoc ~S"""
  Spaceboy server middleware, roughly similar to `Plug`s plug

  Middleware has to implement two functions `c:init/1` and `c:call/2`. For example
  implementation of middleware please look at `Spaceboy.Middleware.Logger` module.
  """
  @moduledoc authors: ["Sgiath <sgiath@pm.me"]

  alias Spaceboy.Conn

  @callback init(opts :: Keyword.t()) :: any()
  @callback call(conn :: Conn.t(), opts :: any()) :: Conn.t()

  @doc ~S"""
  Run a series of Middlewares at runtime.

  If any of the plugs halt, the remaining plugs are not invoked. If the given
  connection was already halted, none of the plugs are invoked either.
  """
  @spec run(conn :: Conn.t(), [{module(), Keyword.t()}]) :: Conn.t()
  def run(%Conn{halted: false} = conn, [{module, opts} | middlewares]) do
    case module.call(conn, module.init(opts)) do
      %Conn{} = conn ->
        run(conn, middlewares)

      other ->
        raise ArgumentError,
              "expected #{inspect(module)} to return Spaceboy.Conn, got: #{inspect(other)}"
    end
  end

  def run(%Conn{halted: true} = conn, _middlewares), do: conn

  def run(conn, []), do: conn
end
