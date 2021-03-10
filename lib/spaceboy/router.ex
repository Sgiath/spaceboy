defmodule Spaceboy.Router do
  @moduledoc """
  Router implementation for Spaceboy server.

  Router is technically a `Spaceboy.Middleware` but it is so havily customized that you would not
  recognize it. But of course you don't have to use this helper module and implement it from scratch
  as `Spaceboy.Middleware`.

  `Spaceboy.Router` is usually last middleware in your `Spaceboy.Server` but it is not requirement.
  """

  @doc """
  Splits path into it's segments

  ## Examples

      iex> Spaceboy.Router.split("/foo/bar")
      ["foo", "bar"]

      iex> Spaceboy.Router.split("/:id/*")
      [":id", "*"]

      iex> Spaceboy.Router.split("/foo//*_bar")
      ["foo", "*_bar"]

  """
  @spec split(String.t()) :: [String.t()]
  def split(path) do
    path
    |> String.split("/")
    |> Enum.filter(fn segment -> segment != "" end)
  end

  @doc """
  Converts path segments to AST pattern representation

  ## Examples

      iex> Spaceboy.Router.convert(["foo", "bar"])
      ["foo", "bar"]

      iex> Spaceboy.Router.convert(["foo", ":bar"])
      ["foo", {:_bar, [], nil}]

      iex> Spaceboy.Router.convert(["foo", ":bar", "baz"])
      ["foo", {:_bar, [], nil}, "baz"]

      iex> Spaceboy.Router.convert(["foo", "*bar"])
      [{:|, [], ["foo", {:_bar, [], nil}]}]

      iex> Spaceboy.Router.convert(["foo", "bar", "*baz"])
      ["foo", {:|, [], ["bar", {:_baz, [], nil}]}]

      iex> Spaceboy.Router.convert(["foo", ":bar", "foobar", "*baz"])
      ["foo", {:_bar, [], nil}, {:|, [], ["foobar", {:_baz, [], nil}]}]

  """
  def convert(segments, acc \\ [])

  def convert([":" <> segment | segments], acc) do
    acc = [{String.to_atom("_#{segment}"), [], nil} | acc]

    convert(segments, acc)
  end

  def convert(["*" <> segment | []], acc) do
    glob(String.to_atom("_#{segment}"), acc)
  end

  def convert(["*" | []], acc), do: glob(:_, acc)

  def convert(["*" <> _segment | _segments], _acc) do
    raise "Glob pattern must be the last one"
  end

  def convert(["*" | _segments], _acc) do
    raise "Glob pattern must be the last one"
  end

  def convert([segment | segments], acc) do
    convert(segments, [segment | acc])
  end

  def convert([], acc), do: Enum.reverse(acc)

  defp glob(segment, [ha | acc]) do
    Enum.reverse([{:|, [], [ha, {segment, [], nil}]} | acc])
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Spaceboy.Middleware

      @before_compile Spaceboy.Router

      import Spaceboy.Router, only: [route: 3, static: 2, static: 3]

      require Logger

      @impl Spaceboy.Middleware
      def init(opts), do: opts

      @impl Spaceboy.Middleware
      def call(%Spaceboy.Conn{path: path} = conn, _opts),
        do: match(conn, Spaceboy.Router.split(path))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def match(%Spaceboy.Conn{path: path} = conn, _catch_all) do
        Logger.warn("Page not found #{path}")

        Spaceboy.Conn.not_found(conn)
      end
    end
  end

  @doc """
  Adds route for URL
  """
  defmacro route(pattern, module, fun) when is_binary(pattern) do
    pattern =
      pattern
      |> split()
      |> convert()

    quote location: :keep do
      def match(%Spaceboy.Conn{} = conn, unquote(pattern)) do
        apply(unquote(module), unquote(fun), [conn])
      end
    end
  end

  @doc """
  Render static files route

  ## Options

    - `ls_dir?: boolean()` - if true (default) directories will list it's files
    - `mime: :guess | String.t()` - what MIME type to use for files. Can be `:guess` to use `MIME`
      library to guess mime type of files. Or can be specific MIME type e.g. "text/gemini" (default)
  """
  defmacro static(prefix, root, opts \\ []) do
    pattern =
      (prefix <> "/*path")
      |> split()
      |> convert()

    opts =
      opts
      |> Keyword.put(:root, root)
      |> Keyword.put(:prefix, prefix)

    quote location: :keep do
      def match(%Spaceboy.Conn{} = conn, unquote(pattern)) do
        Spaceboy.Static.render(conn, unquote(opts))
      end
    end
  end

  @doc """
  Adds redirect
  """
  defmacro redirect(from, to) do
    pattern =
      from
      |> split()
      |> convert()

    quote do
      def match(%Spaceboy.Conn{} = conn, unquote(pattern)) do
        Spaceboy.Conn.redirect(conn, unquote(to))
      end
    end
  end
end
