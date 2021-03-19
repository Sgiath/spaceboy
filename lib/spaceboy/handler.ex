defmodule Spaceboy.Handler do
  @moduledoc false

  alias Spaceboy.Conn
  alias Spaceboy.Header
  alias Spaceboy.Utils

  require Logger

  @behaviour :ranch_protocol

  @doc """
  Spawn new process for connection
  """
  def start_link(ref, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, transport, opts])

    {:ok, pid}
  end

  @doc """
  Initialize new connection

    - handshake
    - load peer certificate
    - create `Spaceboy.Conn` struct
    - enter the connection loop
  """
  def init(ref, _transport, opts) do
    # Establish connection
    {:ok, socket} = :ranch.handshake(ref)

    # Obtain connection info
    {:ok, {peer_ip, _peer_port}} = :ssl.peername(socket)
    {:ok, {_local_ip, port}} = :ssl.sockname(socket)
    {_status, peer_cert} = :ssl.peercert(socket)

    # Set active mode
    :ok = :ranch_ssl.setopts(socket, active: :once)

    # Create Conn struct
    conn = %Conn{
      owner: self(),
      port: port,
      remote_ip: peer_ip,
      peer_cert: peer_cert
    }

    # Start loop
    loop(conn, opts[:server])
  end

  @doc """
  Loop receiving request data as Elixir messages
  """
  def loop(%Conn{} = conn, server) do
    receive do
      {:ssl, socket, data} ->
        try do
          if valid?(data) do
            conn
            |> parse_data(data)
            |> server.call()
            |> case do
              %Conn{state: :unset} ->
                raise "Response not set"

              %Conn{state: :set, body: nil, header: %Header{code: code}} = conn when code != 20 ->
                do_send(conn, socket, Header.format(conn.header))

              %Conn{state: :set, body: body, header: %Header{code: 20} = header} = conn ->
                do_send(conn, socket, [Header.format(header), body])

              %Conn{state: :set_file, body: file, header: %Header{code: 20} = header} = conn ->
                do_send_file(conn, socket, Header.format(header), file)
            end
          else
            Logger.error("Got request out of spec: #{inspect(data)}")

            data =
              "Invalid protocol"
              |> Header.bad_request()
              |> Header.format()

            do_send(conn, socket, data)
          end
        rescue
          err ->
            Logger.error([
              "Internal Server Error\n\n",
              Exception.format(:error, err, __STACKTRACE__)
            ])

            data =
              "Internal Server Error"
              |> Header.permanent_failure()
              |> Header.format()

            do_send(conn, socket, data)
        end

      {:ssl_closed, _socket} ->
        Logger.debug("connection closed")

      {:ssl_error, socket, reason} ->
        Logger.error("SSL Error: #{reason}")
        :ok = :ranch_ssl.close(socket)
        Process.exit(self(), :kill)

      {:ssl_passive, _socket} ->
        Logger.warn("SSL Passive mode")
        loop(conn, server)
    end
  end

  # Check if request is according to specs
  defp valid?("gemini://" <> data), do: String.ends_with?(data, "\r\n")
  defp valid?(_data), do: false

  # Parse request data into the Conn struct
  defp parse_data(%Conn{} = conn, data) do
    %URI{path: path, query: query, authority: host} =
      data
      |> String.trim()
      |> URI.parse()

    %Conn{
      conn
      | request_path: path,
        path_info: Utils.split(path),
        query_string: query,
        host: host
    }
  end

  # Send standard response
  defp do_send(%Conn{before_send: before_send} = conn, socket, data) do
    _conn = Enum.reduce(before_send, conn, fn bs, conn -> bs.(conn) end)

    :ok = :ranch_ssl.send(socket, data)
    :ok = :ranch_ssl.close(socket)
  end

  # Send file response
  defp do_send_file(%Conn{before_send: before_send} = conn, socket, header, file) do
    _conn = Enum.reduce(before_send, conn, fn bs, conn -> bs.(conn) end)

    :ok = :ranch_ssl.send(socket, header)
    {:ok, _sent_bytes} = :ranch_ssl.sendfile(socket, file)
    :ok = :ranch_ssl.close(socket)
  end
end
