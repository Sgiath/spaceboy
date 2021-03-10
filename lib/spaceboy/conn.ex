defmodule Spaceboy.Conn do
  @moduledoc """
  Struct representing Spaceboy connection (request) roughly equivalent to `Plug.Conn`

  This is main struct that will go through the whole request lifetime.

  ## Request

  These values are set by the framework and you are supposed to treat them as read-only

    - `:peer_cert`
    - `:path`
    - `:query`

  ## Response

  You are supposed to set those values during request lifetime

    - `:body | :file`
    - `:header`
    - `:before_send`

  ## Internal

  This values are for internal usage and you are not supposed to touch them

    - `:transport`
    - `:socket`

  """

  use TypedStruct

  alias Spaceboy.Header

  typedstruct do
    field :transport, :ranch_ssl, default: :ranch_ssl
    field :socket, any(), default: {}
    field :peer_cert, {:ok, binary()} | {:error, atom()}
    field :path, String.t()
    field :query, String.t()
    field :body, String.t()
    field :file, Path.t()
    field :header, Header.t()
    field :before_send, [(t -> t)], default: []
  end

  @doc """
  Add function to be run righ before the response is actually send.

  Multiple functions will get executed in FIFO order.

  ## Examples

      iex> conn = Spaceboy.Conn.register_before_send(%Spaceboy.Conn{}, fn conn -> conn end)
      iex> length(conn.before_send)
      1
      iex> is_function(hd(conn.before_send), 1)
      true

  """
  @spec register_before_send(conn :: t, callback :: (t -> t)) :: t
  def register_before_send(%__MODULE__{before_send: before_send} = conn, callback)
      when is_function(callback, 1) do
    %{conn | before_send: [callback | before_send]}
  end

  @doc """
  Add response header and potentially body to the function.

  Fields `:body` and `:file` cannot be both set at the same time.
  """
  @spec resp(conn :: t, header :: Header.t(), body :: String.t() | nil) :: t
  def resp(conn, header, body \\ nil)

  def resp(%__MODULE__{} = conn, %Header{} = header, nil) do
    %{conn | header: header}
  end

  def resp(%__MODULE__{file: nil} = conn, %Header{code: 20} = header, body) do
    %{conn | header: header, body: body}
  end

  def resp(%__MODULE__{file: nil}, %Header{code: code}, _body) do
    raise "Cannot set body with response code #{code}"
  end

  def resp(%__MODULE__{}, %Header{}, _body) do
    raise "Cannot set body while file is also set"
  end

  @doc """
  Add file as response.

  Fields `:file` and `:body` cannot be both set at the same time.
  Third argument is MIME type of the file. If it is not set the function will use `MIME.from_path/1`
  function to guess its type.
  """
  @spec file(conn :: t, file_path :: Path.t(), mime :: String.t() | nil) :: t
  def file(conn, file_path, mime \\ nil)

  def file(%__MODULE__{body: nil} = conn, file_path, nil) do
    file(conn, file_path, MIME.from_path(file_path))
  end

  def file(%__MODULE__{body: nil} = conn, file_path, mime) do
    if File.exists?(file_path) do
      %{conn | header: Header.success(mime), file: file_path}
    else
      raise "File #{file_path} doesn't exists"
    end
  end

  def file(%__MODULE__{}, _file_path, _mime) do
    raise "Cannot set file while body is also set"
  end

  @doc """
  Add text/gemini string as response
  """
  @spec gemini(conn :: t, content :: String.t()) :: t
  def gemini(%__MODULE__{} = conn, content) when is_binary(content) do
    resp(conn, Header.success(), content)
  end

  @doc """
  Add map as JSON response
  """
  @spec json(conn :: t, content :: map()) :: t
  def json(%__MODULE__{} = conn, content) when is_map(content) do
    resp(conn, Header.success("application/json"), Jason.encode!(content))
  end

  @doc """
  Set input response
  """
  @spec input(conn :: t, promt :: String.t()) :: t
  def input(%__MODULE__{} = conn, prompt) do
    resp(conn, Header.input(prompt))
  end

  @doc """
  Set redirect response
  """
  @spec redirect(conn :: t, path :: String.t()) :: t
  def redirect(%__MODULE__{} = conn, path) do
    resp(conn, Header.redirect(path))
  end

  @doc """
  Set not found response
  """
  @spec not_found(conn :: t, prompt :: String.t()) :: t
  def not_found(%__MODULE__{} = conn, prompt \\ "Page not found") do
    resp(conn, Header.not_found(prompt))
  end

  @doc """
  Set client certificate required response
  """
  @spec auth_required(conn :: t, prompt :: String.t()) :: t
  def auth_required(%__MODULE__{} = conn, prompt \\ "Certificate is missing") do
    resp(conn, Header.client_certificate_required(prompt))
  end
end
