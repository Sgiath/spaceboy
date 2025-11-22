if Code.ensure_loaded?(:ranch) do
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
      socket_opts = [
        # :inet6, # This was causing failures in test environment without IPv6
        {:port, opts[:port]},
        {:certfile, opts[:certfile]},
        {:keyfile, opts[:keyfile]},
        {:verify, :verify_peer},
        {:verify_fun, {fn _cert, _event, _init_state -> {:valid, :unknown_user} end, []}},
        {:versions, [:"tlsv1.2", :"tlsv1.3"]}
      ]

      # Add cacertfile if present, otherwise ranch fails if key is nil
      socket_opts =
        if opts[:cacertfile],
          do: [{:cacertfile, opts[:cacertfile]} | socket_opts],
          else: socket_opts

      trans_opts = %{
        num_acceptors: 100,
        max_connections: :infinity,
        connection_type: :supervisor,
        socket_opts: socket_opts
      }

      # Filter out :verify if cacertfile is not present, as it causes "incompatible" error
      socket_opts =
        if opts[:cacertfile], do: socket_opts, else: Keyword.delete(socket_opts, :verify)

      trans_opts = Map.put(trans_opts, :socket_opts, socket_opts)

      :ranch.child_spec(opts[:server], :ranch_ssl, trans_opts, __MODULE__, opts)
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

    @doc ~S"""
    Properly terminate the connection
    """
    @impl Spaceboy.Adapter
    def disconnect(pid) do
      GenServer.cast(pid, :disconnect)
    end

    # Server

    @impl GenServer
    def init({ref, transport, opts}) do
      {:ok, Keyword.put(opts, :transport, transport), {:continue, ref}}
    end

    @impl GenServer
    def handle_continue(ref, state) do
      # Establish connection
      {:ok, socket} = :ranch.handshake(ref)

      # Set active mode
      set_active(socket, state[:transport])

      state =
        state
        |> Keyword.put(:socket, socket)
        |> Keyword.put(:buffer, "")

      {:noreply, state}
    end

    @impl GenServer
    def terminate(_reason, state) do
      if not is_nil(state[:socket]) do
        state[:transport].close(state[:socket])
      end
    end

    @impl GenServer
    def handle_cast({:send, data}, state) do
      state[:transport].send(state[:socket], data)

      {:stop, :shutdown, state}
    end

    def handle_cast({:send_file, header, file}, state) do
      transport = state[:transport]
      :ok = transport.send(state[:socket], header)
      {:ok, _send_bytes} = transport.sendfile(state[:socket], file)

      {:stop, :shutdown, state}
    end

    def handle_cast(:disconnect, state) do
      {:stop, :shutdown, state}
    end

    @impl GenServer
    def handle_info({:ssl, socket, data}, state) do
      buffer = state[:buffer] <> data

      cond do
        byte_size(buffer) > 1024 + 2 ->
          # DoS protection: if buffer is too large, close connection
          Logger.warning("Request too large, closing connection")
          {:stop, :shutdown, Keyword.put(state, :socket, socket)}

        String.ends_with?(data, "\r\n") ->
          # ... processing ...
          {_status, peername} = :ssl.peername(socket)
          {_status, peercert} = :ssl.peercert(socket)

          info = %{
            owner: self(),
            adapter_ref: self(),
            port: state[:port],
            peer_name: peername,
            peer_cert: peercert
          }

          # TODO: is it good idea to launch it as Task?
          {:ok, _pid} = Task.start(Handler, :request, [buffer, info, state])

          {:noreply, Keyword.put(state, :socket, socket)}

        true ->
          set_active(socket, state[:transport])
          {:noreply, Keyword.put(state, :buffer, buffer)}
      end
    end

    def handle_info({:ssl_closed, socket}, state) do
      Logger.warning("client closed connection")
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

    defp set_active(socket, transport) do
      transport.setopts(socket, active: :once)
    end
  end
end
