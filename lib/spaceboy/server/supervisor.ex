defmodule Spaceboy.Server.Supervisor do
  @moduledoc false

  use Supervisor

  alias Spaceboy.Config
  alias Spaceboy.Handler

  require Logger

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

  def init(opts) do
    children = [
      :ranch.child_spec(
        :gemini,
        :ranch_ssl,
        Config.trans_opts(opts),
        Handler,
        opts
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp default({otp_app, module}) do
    otp_app
    |> Application.get_env(module, [])
    |> Keyword.put(:server, module)
  end

  defp log_access_url(mod, opts) do
    Logger.info("Server #{inspect(mod)} started at 0.0.0.0:#{opts[:port]} (gemini)")
    Logger.info("Access #{inspect(mod)} at gemini://#{opts[:host]}")
  end

  defp check_certs(opts) do
    unless File.exists?(opts[:certfile]) and File.exists?(opts[:keyfile]) do
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
      #{IO.ANSI.red()}
      Exiting because Gemini protocol requires TLS Certificate!
      #{IO.ANSI.reset()}
      """)

      System.stop(1)
    end
  end
end
