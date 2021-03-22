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
    ```
    Application.app_dir(:example, "lib/templates/")
    ```

  """

  alias Spaceboy.Conn
  alias Spaceboy.Header

  @doc false
  defmacro __using__(options) do
    quote bind_quoted: [options: options], unquote: true do
      # The default root just assumes Elixir's usual functionality,
      # and it is the user's responsibility to make sure it's right.
      @spaceboy_root Keyword.get(options, :root, "lib/templates/")

      alias Spaceboy.Conn
      import Spaceboy.Conn
      alias Spaceboy.Controller

      @doc ~S"""
      Calls `Spaceboy.Controller.Render` with the appropriate file path,
      relative to the `:root`.
      """
      @spec render(conn :: Conn.t(), template :: String.t(), assigns :: Keyword.t() | map) ::
              String.t()
      def render(conn, template, assigns \\ []) do
        path = Path.join(@spaceboy_root, template)
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
