defmodule Spaceboy.Adapter.ThousandIslandTest do
  use ExUnit.Case, async: false

  # @moduletag :capture_log

  defmodule ServerTI1 do
    use Spaceboy.Server, otp_app: :spaceboy, adapter: Spaceboy.Adapter.ThousandIsland

    defmodule Router do
      use Spaceboy.Router
      route "/", ServerTI1, :index
    end

    middleware Router

    def index(conn) do
      Spaceboy.Conn.resp(conn, Spaceboy.Header.success(), "Hello ThousandIsland")
    end
  end

  setup_all do
    :ssl.start()
    :ok
  end

  defp recv_all(socket, acc \\ "") do
    case :ssl.recv(socket, 0, 1000) do
      {:ok, data} -> recv_all(socket, acc <> data)
      {:error, :closed} -> {:ok, acc}
      {:error, reason} -> {:error, reason}
    end
  end

  test "server starts and accepts TLS connections with ThousandIsland" do
    port = 1970

    opts = [
      port: port,
      certfile: "priv/ssl/cert.pem",
      keyfile: "priv/ssl/key.pem",
      adapter: Spaceboy.Adapter.ThousandIsland
    ]

    {:ok, _pid} = ServerTI1.start_link(opts)

    connect_opts = [:binary, active: false, verify: :verify_none]
    {:ok, socket} = :ssl.connect(~c"localhost", port, connect_opts)

    # Send request
    :ok = :ssl.send(socket, "gemini://localhost:#{port}/\r\n")

    {:ok, response} = recv_all(socket)
    assert response == "20 text/gemini; charset=utf-8\r\nHello ThousandIsland"

    :ssl.close(socket)
    Supervisor.stop(ServerTI1)
  end

  defmodule ServerTI2 do
    use Spaceboy.Server, otp_app: :spaceboy, adapter: Spaceboy.Adapter.ThousandIsland
    # No route needed
  end

  test "DoS protection works" do
    port = 1971

    opts = [
      port: port,
      certfile: "priv/ssl/cert.pem",
      keyfile: "priv/ssl/key.pem",
      adapter: Spaceboy.Adapter.ThousandIsland
    ]

    {:ok, _pid} = ServerTI2.start_link(opts)

    connect_opts = [:binary, active: false, verify: :verify_none]
    {:ok, socket} = :ssl.connect(~c"localhost", port, connect_opts)

    payload = String.duplicate("a", 1030) <> "\r\n"
    :ok = :ssl.send(socket, payload)

    assert {:error, :closed} = :ssl.recv(socket, 0, 1000)
    Supervisor.stop(ServerTI2)
  end

  defmodule RawHandler do
    use ThousandIsland.Handler
    def handle_connection(_socket, state), do: {:continue, state}

    def handle_data(data, socket, state) do
      ThousandIsland.Socket.send(socket, "Echo: " <> data)
      {:close, state}
    end
  end

  test "raw ThousandIsland handler works" do
    port = 1972

    opts = [
      port: port,
      handler_module: RawHandler,
      transport_module: ThousandIsland.Transports.SSL,
      transport_options: [
        certfile: "priv/ssl/cert.pem",
        keyfile: "priv/ssl/key.pem"
      ]
    ]

    {:ok, _pid} = ThousandIsland.start_link(opts)

    connect_opts = [:binary, active: false, verify: :verify_none]
    {:ok, socket} = :ssl.connect(~c"localhost", port, connect_opts)

    :ok = :ssl.send(socket, "test")
    {:ok, response} = :ssl.recv(socket, 0, 1000)
    assert response == "Echo: test"
    :ssl.close(socket)
  end
end
