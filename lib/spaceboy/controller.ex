defmodule Spaceboy.Controller do
  @moduledoc ~S"""
  Controllers group common functionality and are pointed to by routers.

  Spaceboy controllers are verys similar to Phoenix ones, but unlike Phoenix
  there is no concept of a seperate "view" module.

  Controllers are related to Connections, and any module that `use`s this one
  automatically imports `Spaceboy.Conn`.

  ## Options

    * `:root` the directory containing templates that can be used with `render`.
      Defaults to `lib/templates/`, same as Phoenix. You can ensure that it is
      pulling from your project's folder with

        Application.app_dir(:example, "lib/templates/")

  """
  @moduledoc authors: ["Steven vanZyl <rushsteve1@rushsteve1.us>"]

  alias Spaceboy.Conn
  alias Spaceboy.Header

  defmacro __using__(opts) do
    spaceboy_root = Keyword.get(opts, :root, "lib/templates/")

    quote do
      import Spaceboy.Conn

      alias Spaceboy.Conn
      alias Spaceboy.Controller

      def render(%Conn{} = conn, template, assigns \\ []) do
        path = Path.join(unquote(spaceboy_root), template)
        Spaceboy.Controller.render(conn, path, assigns)
      end
    end
  end

  @doc ~S"""
  Takes the connection, the name of a template, and a set of assignments then
  renders the EEx template and sets it as the response to the connection.

  The path to the template file should be absolute, without the `.eex` suffix.
  """
  @spec render(conn :: Conn.t(), template :: binary, assigns :: Keyword.t() | map) :: Conn.t()
  def render(conn, template, assigns \\ [])

  def render(conn, template, assigns) when is_binary(template) and is_map(assigns) do
    render(conn, template, Map.to_list(assigns))
  end

  def render(conn, template, assigns) when is_binary(template) and is_list(assigns) do
    mime = MIME.from_path(template)

    assigns =
      conn.assigns
      |> Map.to_list()
      |> Keyword.merge(assigns)
      |> Keyword.put(:conn, conn)

    rendered = EEx.eval_file(template <> ".eex", assigns)

    Conn.resp(conn, Header.success(mime), rendered)
  end
end
