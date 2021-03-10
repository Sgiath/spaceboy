defmodule Spaceboy.Static do
  @moduledoc """
  Controller handling static files rendering

  You are not supposed to use it directly but with `Spaceboy.Router.static/3` macro which nicely
  wraps its functionality.
  """

  alias Spaceboy.Conn

  @doc """
  Render appropriate content for the path
  """
  @spec render(conn :: Conn.t(), Keyword.t()) :: Conn.t()
  def render(%Conn{path: path} = conn, opts \\ []) do
    # path relative to root dir
    file_path =
      path
      |> String.replace_leading(prefix(opts), "")
      |> String.replace_suffix("/", "")

    if File.dir?(root(opts) <> file_path) do
      render_dir(conn, file_path, opts)
    else
      render_file(conn, file_path, opts)
    end
  end

  defp render_dir(%Conn{path: path} = conn, dir_path, opts) do
    fs_path = root(opts) <> dir_path

    cond do
      File.exists?(fs_path <> "/index.gmi") ->
        opts = Keyword.put(opts, :mime, "text/gemini")

        render_file(conn, dir_path <> "/index.gmi", opts)

      ls_dir?(opts) ->
        files =
          fs_path
          |> File.ls!()
          |> Enum.map(fn file -> "=> #{prefix(opts)}#{dir_path}/#{file}" end)
          |> Enum.join("\n")

        Conn.gemini(conn, dir_template(path, files))

      true ->
        Conn.not_found(conn)
    end
  end

  defp render_file(conn, file_path, opts) do
    fs_path = root(opts) <> file_path

    case mime(opts) do
      :guess ->
        Conn.file(conn, fs_path, MIME.from_path(fs_path))

      mime when is_binary(mime) ->
        Conn.file(conn, fs_path, mime)

      true ->
        raise "Invalid MIME type. Expected :guess or binary. Got: #{inspect(mime(opts))}"
    end
  end

  defp dir_template(path, file_links) do
    """
    # Files in #{path}

    => ../
    #{file_links}
    """
  end

  defp root(opts) do
    opts
    |> Keyword.fetch!(:root)
    |> String.replace_suffix("/", "")
  end

  defp prefix(opts) do
    opts
    |> Keyword.fetch!(:prefix)
    |> String.replace_suffix("/", "")
  end

  defp ls_dir?(opts), do: Keyword.get(opts, :ls_dir?, true)

  defp mime(opts), do: Keyword.get(opts, :mime, "text/gemini")
end
