defmodule Spaceboy.Specification do
  @moduledoc ~S"""
  Check if the request received is according to specification.

  https://gitlab.com/gemini-specification/protocol/-/blob/master/specification.gmi
  """

  @doc ~S"""
  Check the received data against Gemini specification

  ## Examples

      iex> Spaceboy.Specification.check("gemini://localhost/\r\n")
      {:ok, %URI{authority: "localhost", host: "localhost", path: "/", scheme: "gemini"}}

      iex> Spaceboy.Specification.check("gemini://localhost/")
      {:error, "Missing CRLF sequence"}

      iex> Spaceboy.Specification.check("gemini://localhost/\r\nsecond line\r\n")
      {:error, "Multiple lines received"}

      iex> data = String.duplicate("a", 1025) <> "\r\n"
      iex> Spaceboy.Specification.check(data)
      {:error, "Too much data"}

      iex> Spaceboy.Specification.check("https://localhost/\r\n")
      {:error, "Scheme is not gemini"}

      iex> Spaceboy.Specification.check("gemini://user:password@localhost/\r\n")
      {:error, "URI cannot contain user info"}
  """
  def check(data) do
    with {:ok, data} <- end_with_crlf(data),
         {:ok, data} <- one_line(data),
         {:ok, data} <- max_length(data),
         %URI{} = data <- URI.parse(data),
         {:ok, data} <- scheme(data),
         {:ok, data} <- no_user_info(data),
         {:ok, data} <- allowed_hosts(data) do
      {:ok, data}
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
  defp scheme(_data), do: {:error, "Scheme is not gemini"}

  defp no_user_info(%URI{userinfo: nil} = data), do: {:ok, data}
  defp no_user_info(_data), do: {:error, "URI cannot contain user info"}

  defp allowed_hosts(%URI{host: _host} = data) do
    # TODO: check host agains "allowed_hosts" config?
    {:ok, data}
  end
end
