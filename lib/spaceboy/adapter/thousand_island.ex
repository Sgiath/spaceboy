if Code.ensure_loaded?(ThousandIsland) do
  defmodule Spaceboy.Adapter.ThousandIsland do
    @moduledoc false

    @behaviour Spaceboy.Adapter

    alias Spaceboy.Handler

    require Logger

    # Define nested Handler module to avoid child_spec conflict
    defmodule ConnectionHandler do
      use ThousandIsland.Handler
      # Needs to be aliased here for Task.start
      alias Spaceboy.Handler
      require Logger

      @impl ThousandIsland.Handler
      def handle_connection(_socket, state) do
        # Initialize buffer
        {:continue, Map.put(state, :buffer, "")}
      end

      @impl ThousandIsland.Handler
      def handle_data(data, socket, state) do
        buffer = state[:buffer] <> data

        cond do
          byte_size(buffer) > 1024 + 2 ->
            Logger.warning("Request too large, closing connection")
            {:close, state}

          String.ends_with?(buffer, "\r\n") ->
            {:ok, peername} = ThousandIsland.Socket.peername(socket)
            peercert = ThousandIsland.Socket.peercert(socket)

            opts = state

            info = %{
              owner: self(),
              adapter_ref: socket,
              port: opts[:port],
              peer_name: peername,
              peer_cert: peercert
            }

            Task.start(Handler, :request, [buffer, info, opts])

            {:continue, state}

          true ->
            {:continue, Map.put(state, :buffer, buffer)}
        end
      end
    end

    # Spaceboy.Adapter callbacks

    @impl Spaceboy.Adapter
    def child_spec(opts) do
      transport_options = [
        certfile: opts[:certfile],
        keyfile: opts[:keyfile]
      ]

      ti_opts = [
        port: opts[:port],
        transport_module: ThousandIsland.Transports.SSL,
        transport_options: transport_options,
        handler_module: __MODULE__.ConnectionHandler,
        handler_options: Map.new(opts)
      ]

      spec = ThousandIsland.child_spec(ti_opts)
      %{spec | id: opts[:server]}
    end

    @impl Spaceboy.Adapter
    def send(socket, header, body \\ nil) do
      ThousandIsland.Socket.send(socket, header)
      if body, do: ThousandIsland.Socket.send(socket, body)
      ThousandIsland.Socket.close(socket)
      :ok
    end

    @impl Spaceboy.Adapter
    def send_file(socket, header, file) do
      ThousandIsland.Socket.send(socket, header)
      ThousandIsland.Socket.sendfile(socket, file, 0, 0)
      ThousandIsland.Socket.close(socket)
      :ok
    end

    @impl Spaceboy.Adapter
    def disconnect(socket) do
      ThousandIsland.Socket.close(socket)
      :ok
    end
  end
end
