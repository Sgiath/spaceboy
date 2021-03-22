defmodule Spaceboy.Conn do
  @moduledoc ~S"""
  Struct representing Spaceboy connection (request) roughly equivalent to
  `Plug.Conn`

  This is main struct that will go through the whole request lifetime.

  ## Request fields

  These values are set by the framework and you are supposed to treat them as
  read-only.

    - `:scheme` - is always `:gemini` (no other schemes are supported)
    - `:host` - will be set to host from request
    - `:port` - listening port (default 1965)
    - `:remote_ip` - IP address of the client (or closest proxy)
    - `:path_info` - path segments
    - `:request_path` - default path as received from client
    - `:query_string` - query string as received from client
    - `:peer_cert` - client certificate

  ## Fetchabel fields

  These fields are not populated until they are fetched manually.

    - `:request_id` - unique ID, populated by `Spaceboy.Middleware.RequestId`
      middleware
    - `:path_params` - fetched by `Spaceboy.Router`
    - `:query_params` - fetched by `fetch_query_params/1`
    - `:params` - combined field of `:path_params` and `:query_params`

  Those fields requires manual fetching because you don't always want to format
  e.g. query. If you are using query for simple user input (e.g. username) and
  the query looks like `&my_username` you actually don't want to fetch it and
  create params from it.

  ## Response fields

  You are supposed to set those values during request lifetime

    - `:header` - header struct for the response
    - `:body` - response body or file path

  Furthermore, the `before_send` field stores callbacks that are invoked before
  the connection is sent.

  ## Connection fields

    - `:assigns` - user data (currently unused)
    - `:owner` - process which owns the connection
    - `:halted` - the boolean status on whether the pipeline was halted
    - `:state` - the connection state

  The connection state is used to track the connection lifecycle. It starts as
  `:unset` but is changed to `:set` or `:set_file` when response is set. Its
  final result is `:sent`.
  """

  @behaviour Access

  use TypedStruct

  alias Spaceboy.Header

  typedstruct module: Unfetched do
    @moduledoc false

    @typedoc """
    A struct used as default on unfetched fields.

    The `:aspect` key of the struct specifies what field is still unfetched.
    """

    field :aspect, :query_params | :path_params | :params
  end

  @type state :: :unset | :set | :set_file | :sent

  typedstruct do
    # Request fields
    field :scheme, :gemini, default: :gemini
    field :host, String.t(), default: "example.com"
    field :port, :inet.port_number(), default: 1965
    field :remote_ip, :inet.ip_address()
    field :path_info, [String.t()], default: []
    field :request_path, String.t(), default: ""
    field :query_string, String.t()
    field :peer_cert, binary() | :no_peercert, default: :no_peercert

    # Fetchable fields
    field :request_id, binary()
    field :path_params, map() | Unfetched.t(), default: %Unfetched{aspect: :path_params}
    field :query_params, map() | Unfetched.t(), default: %Unfetched{aspect: :query_params}
    field :params, map() | Unfetched.t(), default: %Unfetched{aspect: :params}

    # Response fields
    field :header, Header.t()
    field :body, String.t()
    field :before_send, [(t -> t)], default: []

    # Connection fields
    field :assigns, map(), default: %{}
    field :owner, pid()
    field :halted, boolean(), default: false
    field :state, state(), default: :unset
  end

  @doc ~S"""
  Add function to be run righ before the response is actually send.

  Multiple functions will get executed in FIFO order.

  ## Examples

      iex> conn = Spaceboy.Conn.register_before_send(%Spaceboy.Conn{}, & &1)
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

  @doc ~S"""
  Add response header and potentially body to the function.
  """
  @spec resp(conn :: t, header :: Header.t(), body :: String.t() | nil) :: t
  def resp(conn, header, body \\ nil)

  def resp(%__MODULE__{state: :unset} = conn, %Header{} = header, nil) do
    %{conn | header: header, state: :set}
  end

  def resp(%__MODULE__{state: :unset} = conn, %Header{code: 20} = header, body) do
    %{conn | header: header, body: body, state: :set}
  end

  def resp(%__MODULE__{state: :unset}, %Header{code: code}, _body) do
    raise "Cannot set body with response code #{code}"
  end

  def resp(%__MODULE__{state: state}, _header, _body) when state in [:set, :set_file] do
    raise "Response is already set"
  end

  @doc ~S"""
  Add file as response.

  Third argument is MIME type of the file. If it is not set the function will use
  `MIME.from_path/1` function to guess its type.
  """
  @spec file(conn :: t, file_path :: Path.t(), mime :: String.t() | nil) :: t
  def file(conn, file_path, mime \\ nil)

  def file(%__MODULE__{state: :unset} = conn, file_path, nil) do
    file(conn, file_path, MIME.from_path(file_path))
  end

  def file(%__MODULE__{state: :unset} = conn, file_path, mime) do
    if File.exists?(file_path) do
      %{conn | header: Header.success(mime), state: :set_file, body: file_path}
    else
      raise "File #{file_path} doesn't exists"
    end
  end

  def file(%__MODULE__{state: status}, _file_path, _mime) when status in [:set, :set_file] do
    raise "Response already set"
  end

  @doc ~S"""
  Add text/gemini string as response
  """
  @spec gemini(conn :: t, content :: String.t()) :: t
  def gemini(%__MODULE__{} = conn, content) when is_binary(content) do
    resp(conn, Header.success(), content)
  end

  @doc ~S"""
  Add map as JSON response
  """
  @spec json(conn :: t, content :: map()) :: t
  def json(%__MODULE__{} = conn, content) when is_map(content) do
    resp(conn, Header.success("application/json"), Jason.encode!(content))
  end

  @doc ~S"""
  Set input response
  """
  @spec input(conn :: t, promt :: String.t()) :: t
  def input(%__MODULE__{} = conn, prompt) do
    resp(conn, Header.input(prompt))
  end

  @doc ~S"""
  Set redirect response
  """
  @spec redirect(conn :: t, path :: String.t()) :: t
  def redirect(%__MODULE__{} = conn, path) do
    resp(conn, Header.redirect(path))
  end

  @doc ~S"""
  Set not found response
  """
  @spec not_found(conn :: t, prompt :: String.t()) :: t
  def not_found(%__MODULE__{} = conn, prompt \\ "Page not found") do
    resp(conn, Header.not_found(prompt))
  end

  @doc ~S"""
  Set client certificate required response
  """
  @spec auth_required(conn :: t, prompt :: String.t()) :: t
  def auth_required(%__MODULE__{} = conn, prompt \\ "Certificate is missing") do
    resp(conn, Header.client_certificate_required(prompt))
  end

  @doc ~S"""
  Fetch query params - decode `query_string` to map()
  """
  @spec fetch_query_params(conn :: t) :: t
  def fetch_query_params(%__MODULE__{query_string: query} = conn) do
    fetch_params(%__MODULE__{conn | query_params: URI.decode_query(query)})
  end

  @doc false
  @spec fetch_params(conn :: t) :: t
  def fetch_params(%__MODULE__{query_params: %Unfetched{}, path_params: params} = conn) do
    %__MODULE__{conn | params: params}
  end

  def fetch_params(%__MODULE__{query_params: params, path_params: %Unfetched{}} = conn) do
    %__MODULE__{conn | params: params}
  end

  def fetch_params(%__MODULE__{query_params: q_params, path_params: p_params} = conn) do
    %__MODULE__{conn | params: Map.merge(p_params, q_params)}
  end

  # Access behaviour

  @doc false
  defdelegate fetch(conn, key), to: Map

  @doc false
  defdelegate get_and_update(conn, key, function), to: Map

  @doc false
  defdelegate pop(conn, key), to: Map
end
