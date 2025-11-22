defmodule Spaceboy.Adapter.RanchTest do
  use ExUnit.Case, async: false

  @moduletag :capture_log

  # Define unique modules for each test to avoid name collision
  defmodule Server1 do
    use Spaceboy.Server, otp_app: :spaceboy

    defmodule Router do
      use Spaceboy.Router
      route "/", Server1, :index
    end

    middleware Router

    def index(conn) do
      Spaceboy.Conn.resp(conn, Spaceboy.Header.success(), "Hello Gemini")
    end
  end

  defmodule Server2 do
    use Spaceboy.Server, otp_app: :spaceboy
    # No route needed for DoS test as we blast bytes before request parsing completes
  end

  defmodule Server3 do
    use Spaceboy.Server, otp_app: :spaceboy

    defmodule Router do
      use Spaceboy.Router
      route "/", Server3, :index
    end

    middleware Router

    def index(conn) do
      Spaceboy.Conn.resp(conn, Spaceboy.Header.success(), "Hello Gemini")
    end
  end

  setup_all do
    :ssl.start()
    :ok
  end

  test "server starts and accepts TLS connections" do
    port = 1966

    opts = [
      port: port,
      certfile: "priv/ssl/cert.pem",
      keyfile: "priv/ssl/key.pem"
    ]

    {:ok, _pid} = Server1.start_link(opts)

    connect_opts = [:binary, active: false, verify: :verify_none]
    {:ok, socket} = :ssl.connect(~c"localhost", port, connect_opts)

    # Specify port in URL because Spaceboy checks it against listener port
    :ok = :ssl.send(socket, "gemini://localhost:#{port}/\r\n")

    {:ok, response} = :ssl.recv(socket, 0, 1000)
    assert response == "20 text/gemini; charset=utf-8\r\nHello Gemini"

    :ssl.close(socket)
    # Stop server to free port/name
    Supervisor.stop(Server1)
  end

  test "DoS protection closes connection on large request" do
    port = 1967

    opts = [
      port: port,
      certfile: "priv/ssl/cert.pem",
      keyfile: "priv/ssl/key.pem"
    ]

    {:ok, _pid} = Server2.start_link(opts)

    connect_opts = [:binary, active: false, verify: :verify_none]
    {:ok, socket} = :ssl.connect(~c"localhost", port, connect_opts)

    payload = String.duplicate("a", 1030) <> "\r\n"
    :ok = :ssl.send(socket, payload)

    assert {:error, :closed} = :ssl.recv(socket, 0, 1000)
    Supervisor.stop(Server2)
  end

  test "fragments are rejected (integration)" do
    port = 1968

    opts = [
      port: port,
      certfile: "priv/ssl/cert.pem",
      keyfile: "priv/ssl/key.pem"
    ]

    {:ok, _pid} = Server3.start_link(opts)

    connect_opts = [:binary, active: false, verify: :verify_none]
    {:ok, socket} = :ssl.connect(~c"localhost", port, connect_opts)

    :ok = :ssl.send(socket, "gemini://localhost:#{port}/#frag\r\n")

    {:ok, response} = :ssl.recv(socket, 0, 1000)
    assert response =~ "59 URI cannot contain fragment\r\n"

    :ssl.close(socket)
    Supervisor.stop(Server3)
  end
end
