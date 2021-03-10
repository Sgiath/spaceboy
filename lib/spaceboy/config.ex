defmodule Spaceboy.Config do
  @moduledoc false

  alias Spaceboy.Verify

  @spec trans_opts(Keyword.t()) :: map()
  def trans_opts(opts) do
    %{
      num_acceptors: 100,
      max_connections: :infinity,
      connection_type: :supervisor,
      socket_opts: ssl_opts(opts)
    }
  end

  @spec ssl_opts(Keyword.t()) :: Keyword.t()
  def ssl_opts(opts) do
    [
      port: opts[:port],
      certfile: opts[:certfile],
      keyfile: opts[:keyfile],
      cacertfile: "/dev/null",
      verify: :verify_peer,
      verify_fun: {&Verify.cert/3, []},
      versions: [:"tlsv1.3"]
    ]
  end
end
