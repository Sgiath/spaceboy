defmodule Spaceboy.Server do
  @moduledoc """
  Main configuration for your Spaceboy server. Roughly equivalet to `Phoenix.Endpoint`

  Server requires SSL certificate to function properly. It can be self-signed and you can generate
  one with this command:

  ```
  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj '/CN=localhost'
  ```

  The default location for certificate is: `priv/ssl/` but you can change it to what ever path you
  want via configuration:

  ```
  config :example, Example.Server,
    host: "localhost",
    port: 1965,
    certfile: "priv/ssl/cert.pem,
    keyfile: "priv/ssl/key.pem
  ```

  or when starting your server in Application module:


  ```
  def start(_type, _args) do
    config = [
      host: "localhost",
      port: 1965,
      certfile: "priv/ssl/cert.pem,
      keyfile: "priv/ssl/key.pem
    ]

    children = [
      {Example.Server, config}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Example.Supervisor)
  end
  ```
  """

  defmacro __using__(opts) do
    otp_app = Keyword.get(opts, :otp_app)

    if is_nil(otp_app) do
      raise ":otp_app needs to be set"
    end

    quote do
      @behaviour Spaceboy.Middleware

      import Spaceboy.Server, only: [middleware: 1, middleware: 2]

      @impl Spaceboy.Middleware
      def init(opts \\ []), do: opts

      @impl Spaceboy.Middleware
      def call(conn, opts \\ []) do
        server_call(conn, opts)
      end

      def start_link(opts \\ []) do
        opts = Keyword.put(opts, :otp_app, unquote(otp_app))

        Spaceboy.Server.Supervisor.start_link(__MODULE__, opts)
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      Module.register_attribute(__MODULE__, :middlewares, accumulate: true)
      @before_compile Spaceboy.Server
    end
  end

  defmacro __before_compile__(env) do
    middlewares = Module.get_attribute(env.module, :middlewares)

    quote do
      defp server_call(conn, _opts) do
        Spaceboy.Middleware.run(conn, unquote(middlewares))
      end
    end
  end

  @doc """
  Add middleware to your server configuration
  """
  defmacro middleware(module, opts \\ []) do
    quote do
      @middlewares {unquote(module), unquote(opts)}
    end
  end
end
