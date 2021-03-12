defmodule Spaceboy.Handler do
  @moduledoc false

  alias Spaceboy.Conn
  alias Spaceboy.Header

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
  def init(ref, transport, opts) do
    server = Keyword.fetch!(opts, :server)

    {:ok, socket} = :ranch.handshake(ref)
    peer_cert = :ssl.peercert(socket)

    conn = %Conn{
      transport: transport,
      socket: socket,
      peer_cert: peer_cert
    }

    loop(conn, server)
  end

  @doc """
  Loop receiving request data as Elixir messages
  """
  def loop(%Conn{socket: socket, transport: transport} = conn, server) do
    :ok = transport.setopts(socket, active: :once)

    receive do
      {:ssl, _socket, data} ->
        if valid?(data) do
          conn
          |> parse_data(data)
          |> server.call()
          |> case do
            %Conn{body: nil, file: nil, header: %Header{code: code}} = conn when code != 20 ->
              do_send(conn, Header.format(conn.header))

            %Conn{body: body, file: nil, header: %Header{code: 20}} = conn ->
              do_send(conn, [Header.format(conn.header), body])

            %Conn{body: nil, file: file, header: %Header{code: 20}} = conn ->
              do_send_file(conn, Header.format(conn.header), file)
          end
        else
          Logger.error("Got request out of spec: #{inspect(data)}")

          data =
            "Invalid protocol"
            |> Header.bad_request()
            |> Header.format()

          do_send(conn, data)
        end

      {:ssl_closed, _socket} ->
        Logger.debug("connection closed")

      {:ssl_error, socket, reason} ->
        Logger.error("SSL Error: #{reason}")
        :ok = :ranch_ssl.close(socket)
        Process.exit(self(), :kill)

      {:ssl_passive, socket} ->
        Logger.warn("SSL Passive mode")
        loop(%Conn{conn | socket: socket}, server)
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

      do_send(conn, data)
  end

  # Check if request is according to specs
  defp valid?("gemini://" <> data), do: String.ends_with?(data, "\r\n")
  defp valid?(_data), do: false

  # Parse request data into the Conn struct
  defp parse_data(%Conn{} = conn, data) do
    %URI{path: path, query: query} =
      data
      |> String.trim()
      |> URI.parse()

    %Conn{conn | path: path, query: query}
  end

  # Send standard response
  defp do_send(%Conn{before_send: before_send} = conn, data) do
    %Conn{transport: transport, socket: socket} =
      Enum.reduce(before_send, conn, fn bs, conn -> bs.(conn) end)

    :ok = transport.send(socket, data)
    :ok = transport.close(socket)
  end

  # Send file response
  defp do_send_file(%Conn{before_send: before_send} = conn, header, file) do
    %Conn{transport: transport, socket: socket} =
      Enum.reduce(before_send, conn, fn bs, conn -> bs.(conn) end)

    :ok = transport.send(socket, header)
    {:ok, _sent_bytes} = transport.sendfile(socket, file)
    :ok = transport.close(socket)
  end
end
