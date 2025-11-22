defmodule Spaceboy.Handler do
  @moduledoc false

  alias Spaceboy.Conn
  alias Spaceboy.Header
  alias Spaceboy.Specification
  alias Spaceboy.Utils

  require Logger

  @spec request(data :: binary(), info :: map(), opts :: Keyword.t()) :: :ok
  def request(data, info, opts) do
    case Specification.check(data, opts) do
      {:ok, data} ->
        try do
          info
          |> create_conn(data)
          |> opts[:server].call()
          |> response(opts)
        rescue
          err ->
            internal_server_error(info, opts)

            reraise err, __STACKTRACE__
        end

      {:error, reason} ->
        out_of_spec(info, reason, opts)

      {:error, code, reason} when is_integer(code) ->
        error_response(info, code, reason, opts)
    end
  end

  defp create_conn(info, %URI{path: path, query: query, host: host}) do
    %Conn{}
    |> Map.merge(info)
    |> Map.put(:request_path, path)
    |> Map.put(:path_info, Utils.split(path))
    |> Map.put(:query_string, query)
    |> Map.put(:host, host)
  end

  defp response(%Conn{halted: true, adapter_ref: adapter_ref}, opts) do
    Logger.warning("Connecting halted. Disconnecting from client.")

    opts[:adapter].disconnect(adapter_ref)
  end

  defp response(%Conn{state: :unset}, _opts) do
    raise Spaceboy.OutOfSpecError, "Response not set"
  end

  defp response(%Conn{state: :set, body: nil, header: header} = conn, opts) do
    _conn = Conn.execute_before_send(conn)

    opts[:adapter].send(conn.adapter_ref, Header.format(header), nil)
  end

  defp response(%Conn{state: :set, body: body, header: header} = conn, opts) do
    _conn = Conn.execute_before_send(conn)

    opts[:adapter].send(conn.adapter_ref, Header.format(header), body)
  end

  defp response(%Conn{state: :set_file, body: file, header: header} = conn, opts) do
    _conn = Conn.execute_before_send(conn)

    opts[:adapter].send_file(conn.adapter_ref, Header.format(header), file)
  end

  defp out_of_spec(%{adapter_ref: adapter_ref}, reason, opts) do
    Logger.error("Got request out of spec: #{reason}")

    data =
      reason
      |> Header.bad_request()
      |> Header.format()

    opts[:adapter].send(adapter_ref, data, nil)
  end

  defp internal_server_error(%{adapter_ref: adapter_ref}, opts) do
    Logger.error("Internal Server Error")

    data =
      "Internal Server Error"
      |> Header.temporary_failure()
      |> Header.format()

    opts[:adapter].send(adapter_ref, data, nil)
  end

  defp error_response(%{adapter_ref: adapter_ref}, code, reason, opts) do
    Logger.error("Got request out of spec: #{reason}")

    data = Header.format(%Header{code: code, meta: reason})

    opts[:adapter].send(adapter_ref, data, nil)
  end
end
