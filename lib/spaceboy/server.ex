defmodule Spaceboy.Server do
  @moduledoc ~S"""
  Main configuration for your Spaceboy server. Roughly equivalet to
  `Phoenix.Endpoint`

  ## TLS certificate and configuration

  Server requires TLS certificate to function properly. It can be self-signed and
  you can generate one with this command:

  ```
  mix spaceboy.gen.cert
  ```

  The default location for certificate is: `priv/ssl/` but you can change it to
  whatever path you want via configuration:

  ```elixir
  config :example, Example.Server,
    port: 1965,
    allowed_hosts: [],
    certfile: "priv/ssl/cert.pem",
    keyfile: "priv/ssl/key.pem"
  ```

  or when starting your server in Application module (in case you need
  programatically controlled configuration):

  ```elixir
  def start(_type, _args) do
    config = [
      port: 1965,
      allowed_hosts: [],
      certfile: "priv/ssl/cert.pem",
      keyfile: "priv/ssl/key.pem"
    ]

    children = [
      {Example.Server, config}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Example.Supervisor)
  end
  ```

  ### Other options

    * `:port` port on which the server listens on.
    * `:allowed_hosts` this option dictates which hosts the server considers
      valid. By default it is empty list which means the check is skipped and any
      host is considered valid but if you want to limit which hosts are allowed
      you do that here.

  ## Gemini MIME type

  To save yourself from always passing Gemini mime type when sending file it is
  recommended to add Gemini mime type to `MIME` library configuration:

  ```elixir
  config :mime, :types, %{
    "text/gemini" => ["gmi", "gemini"]
  }
  ```

  and you need to recompile `MIME` library: `mix deps.clean mime --build`
  """
  @moduledoc authors: ["Sgiath <sgiath@sgiath.dev>"]

  defmacro __using__(opts) do
    otp_app = opts[:otp_app] || raise ArgumentError, "expected :otp_app option to be set"

    quote do
      @behaviour Spaceboy.Middleware

      import Spaceboy.Server, only: [middleware: 1, middleware: 2]

      @impl Spaceboy.Middleware
      def init(opts \\ []), do: opts

      @impl Spaceboy.Middleware
      def call(conn, opts \\ []) do
        server_call(conn, opts)
      end

      @spec start_link(opts :: Keyword.t()) :: Supervisor.on_start()
      def start_link(opts \\ []) do
        opts = Keyword.put(opts, :otp_app, unquote(otp_app))

        Spaceboy.Server.Supervisor.start_link(__MODULE__, opts)
      end

      @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
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

  @doc ~S"""
  Add middleware to your server configuration
  """
  defmacro middleware(module, opts \\ []) do
    quote do
      @middlewares {unquote(module), unquote(opts)}
    end
  end
end
