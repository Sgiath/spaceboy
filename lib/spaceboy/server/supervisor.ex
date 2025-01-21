defmodule Spaceboy.Server.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  @spec start_link(module(), Keyword.t()) :: Supervisor.on_start()
  def start_link(module, opts \\ []) do
    otp_app = Keyword.get(opts, :otp_app)

    opts =
      {otp_app, module}
      |> default()
      |> Keyword.merge(opts)

    check_certs(opts)

    case Supervisor.start_link(__MODULE__, opts, name: module) do
      {:ok, _} = ok ->
        log_access_url(module, opts)
        ok

      {:error, _} = error ->
        error
    end
  end

  @impl Supervisor
  def init(opts) do
    children = [
      {opts[:adapter], opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp default({otp_app, module}) do
    otp_app
    |> Application.get_env(module, [])
    |> Keyword.put(:server, module)
    |> Keyword.put(:adapter, Spaceboy.Adapter.Ranch)
    |> Keyword.put_new(:port, 1965)
    |> Keyword.put_new(:allowed_hosts, [])
    |> Keyword.put_new(:certfile, "priv/ssl/cert.pem")
    |> Keyword.put_new(:keyfile, "priv/ssl/key.pem")
  end

  defp log_access_url(mod, opts) do
    host = if opts[:allowed_hosts] == [], do: "localhost", else: hd(opts[:allowed_hosts])

    Logger.info("Server #{inspect(mod)} started at 0.0.0.0:#{opts[:port]} (gemini)")
    Logger.info("Access #{inspect(mod)} at gemini://#{host}")
  end

  defp check_certs(opts) do
    if not (File.exists?(opts[:certfile]) and File.exists?(opts[:keyfile])) do
      IO.puts("""
      #{IO.ANSI.red()}
      \nTLS certificate and private key at location "#{opts[:certfile]}" doesn't exists!
      #{IO.ANSI.yellow()}
      You can create one with:

        mix spaceboy.gen.cert

      Or you can change the location in configuration:

        config #{inspect(opts[:otp_app])}, #{inspect(opts[:server])},
          certfile: "path/to/cert/file.pem",
          keyfile: "path/to/key/file.pem"

      #{IO.ANSI.red()}Exiting because Gemini protocol requires TLS Certificate!
      #{IO.ANSI.reset()}
      """)

      System.stop(1)
    end
  end
end
