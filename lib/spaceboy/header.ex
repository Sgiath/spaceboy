defmodule Spaceboy.Header do
  @moduledoc """
  Struct representing Gemini header response.

  You should not create headers directly - all supported headers has functions with correct codes.
  """

  use TypedStruct

  typedstruct enforce: true do
    field :code, pos_integer()
    field :meta, String.t()
  end

  @doc """
  Correctly format the response header

  ## Examples

      iex> "Test input" |> Spaceboy.Header.input() |> Spaceboy.Header.format()
      "10 Test input\\r\\n"

      iex> Spaceboy.Header.success() |> Spaceboy.Header.format()
      "20 text/gemini; charset=utf-8\\r\\n"

  """
  def format(%__MODULE__{code: code, meta: meta}) do
    "#{code} #{meta}\r\n"
  end

  @gemini_mime "text/gemini; charset=utf-8"

  # INPUT

  def input(prompt) when is_binary(prompt), do: %__MODULE__{code: 10, meta: prompt}
  def sensitive_input(prompt), do: %__MODULE__{code: 11, meta: prompt}

  # SUCCESS

  def success(mime \\ @gemini_mime) when is_binary(mime), do: %__MODULE__{code: 20, meta: mime}

  # REDIRECT

  def redirect(dest), do: %__MODULE__{code: 30, meta: dest}
  def temporary_redirect(dest), do: redirect(dest)
  def permanent_redirect(dest), do: %__MODULE__{code: 31, meta: dest}

  # TEMPORARY FAILURE

  def temporary_failure(reason), do: %__MODULE__{code: 40, meta: reason}
  def server_unavailable(reason), do: %__MODULE__{code: 41, meta: reason}
  def cgi_error(reason), do: %__MODULE__{code: 42, meta: reason}
  def proxy_error(reason), do: %__MODULE__{code: 43, meta: reason}
  def slow_down(wait_time \\ 60), do: %__MODULE__{code: 44, meta: wait_time}

  # PERMANENT FAILURE

  def permanent_failure(desc), do: %__MODULE__{code: 50, meta: desc}
  def not_found(desc), do: %__MODULE__{code: 51, meta: desc}
  def gone(desc), do: %__MODULE__{code: 52, meta: desc}
  def proxy_request_refused(desc), do: %__MODULE__{code: 53, meta: desc}
  def bad_request(desc), do: %__MODULE__{code: 59, meta: desc}

  # CLIENT CERTIFICATE

  def client_certificate_required(prompt), do: %__MODULE__{code: 60, meta: prompt}
  def certificate_not_authorised(prompt), do: %__MODULE__{code: 61, meta: prompt}
  def certificate_not_valid(prompt), do: %__MODULE__{code: 62, meta: prompt}
end
