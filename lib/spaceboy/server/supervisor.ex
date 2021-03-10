defmodule Spaceboy.Server.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(module, opts \\ []) do
    otp_app = Keyword.get(opts, :otp_app)

    opts =
      {otp_app, module}
      |> default()
      |> Keyword.merge(opts)

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
        Spaceboy.Config.trans_opts(opts),
        Spaceboy.Handler,
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
    Logger.info("Server #{inspect(mod)} started at 0.0.0.0:1965 (gemini)")
    Logger.info("Access #{inspect(mod)} at gemini://#{opts[:host]}")
  end
end
