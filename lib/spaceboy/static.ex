defmodule Spaceboy.Static do
  @moduledoc ~S"""
  Controller handling static files rendering

  You are not supposed to use it directly but with `Spaceboy.Router.static/3`
  macro which nicely wraps its functionality.
  """
  @moduledoc authors: ["Sgiath <sgiath@pm.me"]

  alias Spaceboy.Conn
  alias Spaceboy.Controller
  alias Spaceboy.Utils

  @doc ~S"""
  Render appropriate content for the path

  ## Options

    * `:root` - filesystem root path for static files
    * `:prefix` - URL prefix for the static files
    * `:ls_dir?` - list files for dirs which doesn't have "index.gmi" (default
      `true`)
    * `:mime` - can be `:guess` or static MIME type for all files (default
      `"text/gemini; charset=utf-8"`)
  """
  @spec render(conn :: Conn.t(), Keyword.t()) :: Conn.t()
  def render(%Conn{params: %{path: path}} = conn, opts \\ []) do
    opts = normalize(opts)

    if File.dir?(Path.join(opts[:root] ++ path)) do
      render_dir(conn, opts)
    else
      render_file(conn, opts)
    end
  end

  defp render_dir(%Conn{params: %{path: path}} = conn, opts) do
    fs_path = Path.join(opts[:root] ++ path)

    cond do
      File.exists?(fs_path <> "/index.gmi") ->
        # Index file
        opts = Map.put(opts, :mime, "text/gemini")

        # Append "index.gmi" to the path
        conn = update_in(conn, [:params, :path], &Kernel.++(&1, ["index.gmi"]))

        render_file(conn, opts)

      opts[:ls_dir?] ->
        files =
          fs_path
          |> File.ls!()
          |> Enum.map(&"=> /#{Path.join(opts[:prefix] ++ path)}/#{&1}")
          |> Enum.join("\n")

        Controller.gemini(conn, dir_template(path, files))

      true ->
        Controller.not_found(conn)
    end
  end

  defp render_file(%Conn{params: %{path: path}} = conn, opts) do
    fs_path = Path.join(opts[:root] ++ path)

    case opts[:mime] do
      :guess ->
        Conn.file(conn, fs_path, MIME.from_path(fs_path))

      mime when is_binary(mime) ->
        Conn.file(conn, fs_path, mime)

      true ->
        raise ArgumentError, "expected :guess or binary as MIME, got: #{inspect(opts[:mime])}"
    end
  end

  defp dir_template(path, file_links) do
    """
    # Files in #{path}

    => ../
    #{file_links}
    """
  end

  defp normalize(opts) do
    %{
      root: Utils.split(opts[:root]),
      prefix: Utils.split(opts[:prefix]),
      ls_dir?: Keyword.get(opts, :ls_dir?, true),
      mime: Keyword.get(opts, :mime, "text/gemini; charset=utf-8")
    }
  end
end
