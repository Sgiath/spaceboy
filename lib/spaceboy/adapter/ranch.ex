defmodule Spaceboy.Adapter.Ranch do
  @moduledoc false

  @behaviour :ranch_protocol
  @behaviour Spaceboy.Adapter

  use GenServer

  alias Spaceboy.Handler

  require Logger

  # Client API

  @impl :ranch_protocol
  def start_link(ref, transport, opts) do
    GenServer.start_link(opts[:adapter], {ref, transport, opts})
  end

  @impl Spaceboy.Adapter
  def child_spec(opts) do
    trans_opts = %{
      num_acceptors: 100,
      max_connections: :infinity,
      connection_type: :supervisor,
      socket_opts: [
        port: opts[:port],
        certfile: opts[:certfile],
        keyfile: opts[:keyfile],
        cacertfile: "/dev/null",
        verify: :verify_peer,
        verify_fun: {fn _cert, _event, _init_state -> {:valid, :unknown_user} end, []},
        versions: [:"tlsv1.3"]
      ]
    }

    :ranch.child_spec(:gemini, :ranch_ssl, trans_opts, __MODULE__, opts)
  end

  @doc ~S"""
  Send data through the socket
  """
  @impl Spaceboy.Adapter
  def send(pid, header, body \\ nil)

  def send(pid, header, nil) do
    GenServer.cast(pid, {:send, header})
  end

  def send(pid, header, body) do
    GenServer.cast(pid, {:send, [header, body]})
  end

  @doc ~S"""
  Send file through the socket
  """
  @impl Spaceboy.Adapter
  def send_file(pid, header, file) do
    GenServer.cast(pid, {:send_file, header, file})
  end

  # Server

  @impl GenServer
  def init({ref, _transport, opts}) do
    {:ok, opts, {:continue, ref}}
  end

  @impl GenServer
  def handle_continue(ref, state) do
    # Establish connection
    {:ok, socket} = :ranch.handshake(ref)

    # Set active mode
    :ok = :ranch_ssl.setopts(socket, active: :once)

    {:noreply, Keyword.put(state, :socket, socket)}
  end

  @impl GenServer
  def terminate(_reason, state) do
    :ranch_ssl.close(state[:socket])
  end

  @impl GenServer
  def handle_cast({:send, data}, state) do
    :ranch_ssl.send(state[:socket], data)

    {:stop, :normal, state}
  end

  def handle_cast({:send_file, header, file}, state) do
    :ok = :ranch_ssl.send(state[:socket], header)
    {:ok, _send_bytes} = :ranch_ssl.sendfile(state[:socket], file)

    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info({:ssl, socket, data}, state) do
    {:ok, {peer_ip, _peer_port}} = :ssl.peername(socket)
    {:ok, {_local_ip, port}} = :ssl.sockname(socket)
    {_status, peer_cert} = :ssl.peercert(socket)

    info = %{
      owner: self(),
      port: port,
      remote_ip: peer_ip,
      peer_cert: peer_cert
    }

    # TODO: is it good idea to launch it as Task?
    {:ok, _pid} = Task.start(Handler, :request, [data, info, state])

    {:noreply, Keyword.put(state, :socket, socket)}
  end

  def handle_info({:ssl_closed, socket}, state) do
    Logger.warning("connection closed")
    {:stop, :shutdown, Keyword.put(state, :socket, socket)}
  end

  def handle_info({:ssl_error, socket, reason}, state) do
    Logger.error("SSL error: #{reason}")
    {:stop, :shutdown, Keyword.put(state, :socket, socket)}
  end

  def handle_info({:ssl_passive, socket}, state) do
    Logger.warning("SSL passive mode")
    {:noreply, Keyword.put(state, :socket, socket)}
  end
end
