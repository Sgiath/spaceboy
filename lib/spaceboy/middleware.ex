defmodule Spaceboy.Middleware do
  @moduledoc """
  Spaceboy server middleware, roughly similar to `Plug`s plug

  Middleware has to implement two functions `init/1` and `call/2`. For example
  implementation of middleware please look at `Spaceboy.Middleware.Logger` module.
  """

  @callback init(opts :: Keyword.t()) :: any()
  @callback call(conn :: Spaceboy.Conn.t(), opts :: any()) :: Spaceboy.Conn.t()

  @doc false
  def run(%Spaceboy.Conn{} = conn, [{module, opts} | middlewares]) do
    case module.call(conn, module.init(opts)) do
      %Spaceboy.Conn{} = conn ->
        run(conn, middlewares)

      other ->
        raise "Expected #{inspect(module)} to return Spaceboy.Conn, got: #{inspect(other)}"
    end
  end

  def run(conn, []), do: conn
end
