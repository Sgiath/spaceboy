defmodule Spaceboy.Config do
  @moduledoc false

  def trans_opts(opts) do
    %{
      num_acceptors: 100,
      max_connections: :infinity,
      connection_type: :supervisor,
      socket_opts: ssl_opts(opts)
    }
  end

  def ssl_opts(opts) do
    [
      port: opts[:port],
      certfile: opts[:certfile],
      keyfile: opts[:keyfile],
      cacertfile: "/dev/null",
      verify: :verify_peer,
      verify_fun: {fn _, _, _ -> {:valid, :unknown_user} end, []},
      versions: [:"tlsv1.3"]
    ]
  end
end
