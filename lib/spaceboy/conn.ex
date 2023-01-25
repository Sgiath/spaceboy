defmodule Spaceboy.Conn do
  @moduledoc ~S"""
  Struct representing Spaceboy connection (request) roughly equivalent to
  `Plug.Conn`

  This is main struct that will go through the whole request lifetime.

  ## Request fields

  These values are set by the framework and you are supposed to treat them as
  read-only.

    * `:scheme` - is always `:gemini` (no other schemes are supported)
    * `:host` - will be set to host from request
    * `:port` - listening port (default 1965)
    * `:remote_ip` - IP address of the client (or closest proxy)
    * `:path_info` - path segments
    * `:request_path` - default path as received from client
    * `:query_string` - query string as received from client
    * `:peer_cert` - client certificate

  ## Fetchable fields

  These fields are not populated until they are fetched manually.

    * `:request_id` - unique ID, populated by `Spaceboy.Middleware.RequestId`
      middleware
    * `:path_params` - fetched by `Spaceboy.Router`
    * `:query_params` - fetched by `fetch_query_params/1`
    * `:params` - combined field of `:path_params` and `:query_params`

  Those fields requires manual fetching because you don't always want to format
  e.g. query. If you are using query for simple user input (e.g. username) and
  the query looks like `?my_username` you actually don't want to fetch it and
  create params from it because they would look like: `%{"my_username" => ""}`

  ## Response fields

  You are supposed to set those values during request lifetime with the functions
  in this module:

    * `:header` - header struct for the response
    * `:body` - response body or file path

  Furthermore, the `:before_send` field stores callbacks that are invoked before
  the connection is sent.

  ## Connection fields

    * `:assigns` - user data
    * `:halted` - the boolean status on whether the pipeline was halted
    * `:state` - the connection state
    * `:owner` - process which owns the connection

  The connection state is used to track the connection lifecycle. It starts as
  `:unset` but is changed to `:set` or `:set_file` when response is set. Its
  final result is `:sent`.
  """
  @moduledoc authors: ["Sgiath <sgiath@sgiath.dev>"]

  @behaviour Access

  use TypedStruct

  alias Spaceboy.Conn.Unfetched
  alias Spaceboy.Header

  @type state :: :unset | :set | :set_file | :sent

  typedstruct do
    @typedoc "Connection struct which holds all the data related to Gemini connection"

    # Request fields
    field :scheme, :gemini, default: :gemini
    field :host, String.t(), default: "example.com"
    field :port, :inet.port_number(), default: 1965
    field :peer_name, {:inet.ip_address(), :inet.port_number()}
    field :peer_cert, binary() | :no_peercert, default: :no_peercert
    field :path_info, [String.t()], default: []
    field :request_path, String.t(), default: ""
    field :query_string, String.t()

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
    field :assigns, Keyword.t(), default: []
    field :owner, pid()
    field :halted, boolean(), default: false
    field :state, state(), default: :unset
  end

  @doc ~S"""
  Add function to be run right before the response is actually send.

  Multiple functions will get executed in LIFO order.
  """
  @spec register_before_send(conn :: t, callback :: (t -> t)) :: t
  def register_before_send(%__MODULE__{} = conn, callback) when is_function(callback, 1) do
    Map.update(conn, :before_send, [], fn bs -> [callback | bs] end)
  end

  @doc false
  @spec execute_before_send(conn :: t) :: t
  def execute_before_send(%__MODULE__{before_send: before_send} = conn) do
    before_send
    |> Enum.reverse()
    |> Enum.reduce(conn, fn bs, conn -> bs.(conn) end)
  end

  @doc ~S"""
  Assigns a value to a key in the connection
  """
  @spec assign(conn :: t, key :: atom(), value :: term()) :: t
  def assign(%__MODULE__{} = conn, key, value) when is_atom(key) do
    put_in(conn, [:assigns, key], value)
  end

  @doc ~S"""
  Assigns multiple values to keys in the connection.

  Equivalent to multiple calls to `assign/3`
  """
  @spec merge_assigns(conn :: t, assigns :: Keyword.t()) :: t
  def merge_assigns(%__MODULE__{} = conn, assigns) when is_list(assigns) do
    Map.update!(conn, :assigns, &Keyword.merge(&1, assigns))
  end

  @doc ~S"""
  Set response header and potentially body to the function.
  """
  @spec resp(conn :: t, header :: Header.t(), body :: String.t() | nil) :: t
  def resp(conn, header, body \\ nil)

  def resp(%__MODULE__{} = conn, %Header{} = header, nil) do
    conn
    |> Map.put(:header, header)
    |> Map.put(:state, :set)
  end

  def resp(%__MODULE__{} = conn, %Header{code: 20} = header, body) do
    conn
    |> Map.put(:header, header)
    |> Map.put(:body, body)
    |> Map.put(:state, :set)
  end

  def resp(%__MODULE__{}, %Header{code: code}, _body) do
    raise Spaceboy.OutOfSpecError, "Cannot set body with response code #{code}"
  end

  @doc ~S"""
  Set file as response.

  Third argument is MIME type of the file. If it is not set the function will use
  `MIME.from_path/1` function to guess its type.
  """
  @spec file(conn :: t, file_path :: Path.t(), mime :: String.t() | nil) :: t
  def file(conn, file_path, mime \\ nil)

  def file(%__MODULE__{} = conn, file_path, nil) do
    file(conn, file_path, MIME.from_path(file_path))
  end

  def file(%__MODULE__{} = conn, file_path, mime) do
    if File.exists?(file_path) do
      conn
      |> Map.put(:header, Header.success(mime))
      |> Map.put(:body, file_path)
      |> Map.put(:state, :set_file)
    else
      raise ArgumentError, "File #{file_path} doesn't exists"
    end
  end

  @doc ~S"""
  Fetch query params - decode `:query_string` to `t:map()`
  """
  @spec fetch_query_params(conn :: t) :: t
  def fetch_query_params(%__MODULE__{query_string: query} = conn) do
    conn
    |> Map.put(:query_params, URI.decode_query(query))
    |> fetch_params()
  end

  @doc false
  @spec fetch_params(conn :: t) :: t
  def fetch_params(%__MODULE__{query_params: %Unfetched{}, path_params: params} = conn) do
    Map.put(conn, :params, params)
  end

  def fetch_params(%__MODULE__{query_params: params, path_params: %Unfetched{}} = conn) do
    Map.put(conn, :params, params)
  end

  def fetch_params(%__MODULE__{query_params: q_params, path_params: p_params} = conn) do
    Map.put(conn, :params, Map.merge(p_params, q_params))
  end

  # Access behaviour

  @doc false
  defdelegate fetch(conn, key), to: Map

  @doc false
  defdelegate get_and_update(conn, key, function), to: Map

  @doc false
  defdelegate pop(conn, key), to: Map
end
