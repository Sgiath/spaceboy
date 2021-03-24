defmodule Spaceboy.Router do
  @moduledoc ~S"""
  Router implementation for Spaceboy server.

  Router is technically a `Spaceboy.Middleware` but it is so havily customized
  that you would not recognize it. But of course you don't have to use this
  helper module and implement it from scratch as `Spaceboy.Middleware`.

  `Spaceboy.Router` is usually last middleware in your `Spaceboy.Server` but it
  is not requirement.
  """
  @moduledoc authors: ["Sgiath <sgiath@pm.me"]

  alias Spaceboy.Router.Builder
  alias Spaceboy.Utils

  defmacro __using__(_opts) do
    quote do
      @behaviour Spaceboy.Middleware

      @before_compile Spaceboy.Router

      import Spaceboy.Router, only: [route: 3, static: 2, static: 3]

      require Logger

      @impl Spaceboy.Middleware
      def init(opts), do: opts

      @impl Spaceboy.Middleware
      def call(%Spaceboy.Conn{path_info: path} = conn, _opts),
        do: match(conn, path)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def match(%Spaceboy.Conn{request_path: path} = conn, _catch_all) do
        Logger.warning("Page not found #{path}")

        Spaceboy.Conn.not_found(conn)
      end
    end
  end

  @doc ~S"""
  Adds route for URL
  """
  defmacro route(pattern, module, fun) when is_binary(pattern) do
    {pattern, params} = build(pattern)

    quote location: :keep do
      def match(%Spaceboy.Conn{} = conn, unquote(pattern)) do
        conn = Spaceboy.Conn.fetch_params(%{conn | path_params: unquote(params)})

        apply(unquote(module), unquote(fun), [conn])
      end
    end
  end

  @doc ~S"""
  Render static files route

  ## Options

  See `Spaceboy.Static.render/2` for options (`:root` and `:prefix` are populated
  automatically ;) )
  """
  defmacro static(prefix, root, opts \\ []) do
    {pattern, params} = build(prefix <> "/*path")

    opts =
      opts
      |> Keyword.put(:root, root)
      |> Keyword.put(:prefix, prefix)

    quote location: :keep do
      def match(%Spaceboy.Conn{} = conn, unquote(pattern)) do
        conn = Spaceboy.Conn.fetch_params(%Spaceboy.Conn{conn | path_params: unquote(params)})

        Spaceboy.Static.render(conn, unquote(opts))
      end
    end
  end

  @doc ~S"""
  Adds redirect
  """
  defmacro redirect(from, to) do
    {pattern, _params} = build(from)

    quote do
      def match(%Spaceboy.Conn{} = conn, unquote(pattern)) do
        Spaceboy.Conn.redirect(conn, unquote(to))
      end
    end
  end

  # Build pattern and params AST
  defp build(path) do
    path
    |> Utils.split()
    |> Builder.convert()
  end
end
