defmodule Spaceboy.Specification do
  @moduledoc ~S"""
  Check if the request received is according to specification.

  https://gitlab.com/gemini-specification/protocol/-/blob/master/specification.gmi
  """
  @moduledoc authors: ["Sgiath <sgiath@sgiath.dev>"]

  @doc ~S"""
  Check the received data against Gemini specification

  ## Examples

      iex> Spaceboy.Specification.check("gemini://localhost/\r\n")
      {:ok, %URI{authority: "localhost", host: "localhost", path: "/", scheme: "gemini"}}

  """
  @spec check(data :: binary(), opts :: Keyword.t()) ::
          {:ok, URI.t()} | {:error, String.t()} | {:error, integer(), String.t()}
  def check(data, opts \\ []) do
    # credo:disable-for-next-line
    with {:ok, data} <- valid_utf8(data),
         {:ok, data} <- end_with_crlf(data),
         {:ok, data} <- one_line(data),
         {:ok, data} <- max_length(data),
         %URI{} = data <- URI.parse(data),
         {:ok, data} <- scheme(data),
         {:ok, data} <- no_user_info(data),
         {:ok, data} <- allowed_port(data, opts[:port]),
         {:ok, data} <- allowed_hosts(data, opts[:allowed_hosts]) do
      {:ok, data}
    end
  end

  defp valid_utf8(data) do
    if String.valid?(data) do
      {:ok, data}
    else
      {:error, "URL contains not valid characters"}
    end
  end

  defp end_with_crlf(data) do
    if String.ends_with?(data, "\r\n") do
      {:ok, String.replace_suffix(data, "\r\n", "")}
    else
      {:error, "Missing CRLF sequence"}
    end
  end

  defp one_line(data) do
    if String.contains?(data, "\n") or String.contains?(data, "\r") do
      {:error, "Multiple lines received"}
    else
      {:ok, data}
    end
  end

  defp max_length(data) do
    if byte_size(data) <= 1024 do
      {:ok, data}
    else
      {:error, "Too much data"}
    end
  end

  defp scheme(%URI{scheme: "gemini"} = data), do: {:ok, data}
  defp scheme(%URI{scheme: nil}), do: {:error, "Missing scheme"}
  defp scheme(_data), do: {:error, 53, "Scheme is not gemini"}

  defp no_user_info(%URI{userinfo: nil} = data), do: {:ok, data}
  defp no_user_info(_data), do: {:error, "URI cannot contain user info"}

  defp allowed_port(%URI{port: nil} = data, 1965), do: {:ok, data}
  defp allowed_port(%URI{port: port} = data, port), do: {:ok, data}
  defp allowed_port(%URI{}, _port), do: {:error, 53, "Incorrect port number"}

  defp allowed_hosts(%URI{} = data, nil), do: {:ok, data}
  defp allowed_hosts(%URI{} = data, []), do: {:ok, data}

  defp allowed_hosts(%URI{host: host} = data, hosts) do
    if host in hosts do
      {:ok, data}
    else
      {:error, 53, "Host #{host} is not allowed"}
    end
  end
end
