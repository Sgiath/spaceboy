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

  defmacro __using__(opts) do
    spaceboy_root = Keyword.get(opts, :root, "lib/templates/")

    quote do
      import Spaceboy.Conn, except: [render: 3]

      alias Spaceboy.Conn
      alias Spaceboy.Controller

      @spec render(conn :: Conn.t(), template :: Path.t(), assigns :: Keyword.t()) :: Conn.t()
      def render(%Conn{} = conn, template, assigns \\ []) do
        path = Path.join(unquote(spaceboy_root), template)

        conn
        |> Conn.merge_assigns(assigns)
        |> Conn.render(path)
      end
    end
  end
end
