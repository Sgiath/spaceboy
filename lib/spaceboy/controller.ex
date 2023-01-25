defmodule Spaceboy.Controller do
  @moduledoc ~S"""
  Controllers group common functionality and are pointed to by routers.

  Spaceboy controllers are very similar to Phoenix ones, but unlike Phoenix
  there is no concept of a separate "view" module.

  Controllers are related to Connections, and any module that `use`s this one
  automatically imports `Spaceboy.Conn`.

  ## Options

    * `:root` the directory containing templates that can be used with `render`.
      Defaults to `lib/templates/`, same as Phoenix. It is always relative to
      your application root folder.

  """
  @moduledoc authors: ["Steven vanZyl <rushsteve1@rushsteve1.us>"]

  alias Spaceboy.Conn
  alias Spaceboy.Header

  defmacro __using__(opts) do
    template_root = opts[:root] || raise ArgumentError, "expected :root to be given as an option"

    quote do
      import Spaceboy.Controller, except: [render: 3]

      @spec render(conn :: Spaceboy.Conn.t(), template :: Path.t(), assigns :: Keyword.t()) ::
              Spaceboy.Conn.t()
      def render(%Spaceboy.Conn{} = conn, template, assigns \\ []) do
        path = Path.join([unquote(template_root), template])

        conn
        |> Spaceboy.Conn.merge_assigns(assigns)
        |> Spaceboy.Controller.render(path)
      end
    end
  end

  @doc ~S"""
  Set response as rendered template
  """
  @spec render(conn :: Conn.t(), template :: Path.t(), mime :: String.t() | nil) :: Conn.t()
  def render(conn, template, mime \\ nil)

  def render(%Conn{} = conn, template, nil) do
    render(conn, template, MIME.from_path(template))
  end

  def render(%Conn{assigns: assigns} = conn, template, mime) do
    assigns = Keyword.put(assigns, :conn, conn)
    rendered = EEx.eval_file(template <> ".eex", assigns)

    Conn.resp(conn, Header.success(mime), rendered)
  end

  @doc ~S"""
  Set text/gemini string as response
  """
  @spec gemini(conn :: Conn.t(), content :: String.t()) :: Conn.t()
  def gemini(%Conn{} = conn, content) when is_binary(content) do
    Conn.resp(conn, Header.success(), content)
  end

  if Code.ensure_loaded?(Jason) do
    @doc ~S"""
    Set map as JSON response

    This function is only defined if you specifically install optional `Jason`
    dependency. This is only place where `Jason` library is used and arguably it
    is not too common function so it is optional.

        {:jason, "~> 1.2"},

    """
    @spec json(conn :: Conn.t(), content :: map()) :: Conn.t()
    def json(%Conn{} = conn, content) when is_map(content) do
      Conn.resp(conn, Header.success("application/json"), Jason.encode!(content))
    end
  end

  @doc ~S"""
  Set text/plain string as response
  """
  @spec text(conn :: Conn.t(), content :: String.t()) :: Conn.t()
  def text(%Conn{} = conn, content) when is_binary(content) do
    Conn.resp(conn, Header.success("text/plain"), content)
  end

  @doc ~S"""
  Set input response
  """
  @spec input(conn :: Conn.t(), prompt :: String.t()) :: Conn.t()
  def input(%Conn{} = conn, prompt) do
    Conn.resp(conn, Header.input(prompt))
  end

  @doc ~S"""
  Set redirect response
  """
  @spec redirect(conn :: Conn.t(), path :: String.t()) :: Conn.t()
  def redirect(%Conn{} = conn, path) do
    Conn.resp(conn, Header.redirect(path))
  end

  @doc ~S"""
  Set not found response
  """
  @spec not_found(conn :: Conn.t(), prompt :: String.t()) :: Conn.t()
  def not_found(%Conn{} = conn, prompt \\ "Page not found") do
    Conn.resp(conn, Header.not_found(prompt))
  end

  @doc ~S"""
  Set client certificate required response
  """
  @spec auth_required(conn :: Conn.t(), prompt :: String.t()) :: Conn.t()
  def auth_required(%Conn{} = conn, prompt \\ "Certificate is missing") do
    Conn.resp(conn, Header.client_certificate_required(prompt))
  end
end
