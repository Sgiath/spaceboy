defmodule Spaceboy.Handler do
  @moduledoc false

  @behaviour :ranch_protocol

  alias Spaceboy.Conn
  alias Spaceboy.Header
  alias Spaceboy.Specification
  alias Spaceboy.Utils

  require Logger

  def start_link(ref, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, transport, opts])

    {:ok, pid}
  end

  def init(ref, _transport, opts) do
    # Establish connection
    {:ok, socket} = :ranch.handshake(ref)

    # Set active mode
    :ok = :ranch_ssl.setopts(socket, active: :once)

    socket
    |> create_conn()
    |> loop(opts[:server])
  end

  def loop(%Conn{} = conn, server) do
    receive do
      {:ssl, socket, data} ->
        process_data(conn, server, socket, data)

      {:ssl_closed, socket} ->
        Logger.warning("connection closed")
        :ranch_ssl.close(socket)

      {:ssl_error, socket, reason} ->
        Logger.error("SSL Error: #{reason}")
        :ranch_ssl.close(socket)

      {:ssl_passive, _socket} ->
        Logger.warning("SSL Passive mode")
        loop(conn, server)
    end
  end

  # Parse request data into the Conn struct
  defp parse_data(%Conn{} = conn, %URI{path: path, query: query, authority: host}) do
    %Conn{
      conn
      | request_path: path,
        path_info: Utils.split(path),
        query_string: query,
        host: host
    }
  end

  # Create new Conn struct from socket
  defp create_conn(socket) do
    # Obtain connection info
    {:ok, {peer_ip, _peer_port}} = :ssl.peername(socket)
    {:ok, {_local_ip, port}} = :ssl.sockname(socket)
    {_status, peer_cert} = :ssl.peercert(socket)

    %Conn{
      owner: self(),
      port: port,
      remote_ip: peer_ip,
      peer_cert: peer_cert
    }
  end

  defp internal_server_error do
    "Internal Server Error"
    |> Header.temporary_failure()
    |> Header.format()
  end

  defp invalid_request(reason) do
    reason
    |> Header.bad_request()
    |> Header.format()
  end

  defp process_data(conn, server, socket, data) do
    case Specification.check(data) do
      {:ok, data} ->
        try do
          conn
          |> parse_data(data)
          |> server.call()
          |> respond(socket)
        rescue
          err ->
            Logger.error("Internal Server Error")
            do_send(conn, socket, internal_server_error())

            reraise err, __STACKTRACE__
        end

      {:error, reason} ->
        Logger.error("Got request out of spec: #{reason}")
        do_send(conn, socket, invalid_request(reason))
    end
  end

  defp respond(%Conn{state: :unset}, _socket) do
    raise "Response not set"
  end

  defp respond(%Conn{state: :set, body: nil, header: header} = conn, socket) do
    do_send(conn, socket, Header.format(header))
  end

  defp respond(%Conn{state: :set, body: body, header: header} = conn, socket) do
    do_send(conn, socket, [Header.format(header), body])
  end

  defp respond(%Conn{state: :set_file, body: file, header: header} = conn, socket) do
    do_send_file(conn, socket, Header.format(header), file)
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
