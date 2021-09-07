defmodule Spaceboy.Header do
  @moduledoc ~S"""
  Struct representing Gemini header response.

  You should not create headers directly - all supported headers has functions
  with correct codes.
  """
  @moduledoc authors: ["Sgiath <sgiath@sgiath.dev>"]

  use TypedStruct

  typedstruct do
    @typedoc "Struct representing Gemini header data"

    field :code, pos_integer(), enforce: true
    field :meta, String.t()
  end

  defguard is_status_code(code) when is_integer(code) and code >= 10 and code <= 69
  defguard is_error_code(code) when is_status_code(code) and code >= 40 and code <= 69

  @doc ~S"""
  Correctly format the response header

  ## Examples

      iex> "Test input" |> Spaceboy.Header.input() |> Spaceboy.Header.format()
      "10 Test input\r\n"

      iex> Spaceboy.Header.success() |> Spaceboy.Header.format()
      "20 text/gemini; charset=utf-8\r\n"

  """
  @doc category: :utils
  @spec format(header :: t) :: String.t()
  def format(%__MODULE__{code: code, meta: nil}) when is_error_code(code) do
    "#{code}\r\n"
  end

  def format(%__MODULE__{code: code, meta: meta}) when is_status_code(code) and is_binary(meta) do
    "#{code} #{meta}\r\n"
  end

  @gemini_mime "text/gemini; charset=utf-8"

  # INPUT

  @doc category: :input
  @spec input(prompt :: String.t()) :: t
  def input(prompt) when is_binary(prompt), do: %__MODULE__{code: 10, meta: prompt}

  @doc category: :input
  @spec sensitive_input(prompt :: String.t()) :: t
  def sensitive_input(prompt), do: %__MODULE__{code: 11, meta: prompt}

  # SUCCESS

  @doc category: :success
  @spec success(mime :: String.t()) :: t
  def success(mime \\ @gemini_mime) when is_binary(mime), do: %__MODULE__{code: 20, meta: mime}

  # REDIRECT

  @doc category: :redirect
  @spec redirect(dest :: String.t()) :: t
  def redirect(dest) when is_binary(dest), do: %__MODULE__{code: 30, meta: dest}

  @doc category: :redirect
  @spec temporary_redirect(dest :: String.t()) :: t
  def temporary_redirect(dest) when is_binary(dest), do: redirect(dest)

  @doc category: :redirect
  @spec permanent_redirect(dest :: String.t()) :: t
  def permanent_redirect(dest) when is_binary(dest), do: %__MODULE__{code: 31, meta: dest}

  # TEMPORARY FAILURE

  @doc category: :temporary_failure
  @spec temporary_failure(reason :: String.t() | nil) :: t
  def temporary_failure(reason \\ nil) when is_nil(reason) or is_binary(reason),
    do: %__MODULE__{code: 40, meta: reason}

  @doc category: :temporary_failure
  @spec server_unavailable(reason :: String.t() | nil) :: t
  def server_unavailable(reason \\ nil) when is_nil(reason) or is_binary(reason),
    do: %__MODULE__{code: 41, meta: reason}

  @doc category: :temporary_failure
  @spec cgi_error(reason :: String.t() | nil) :: t
  def cgi_error(reason \\ nil) when is_nil(reason) or is_binary(reason),
    do: %__MODULE__{code: 42, meta: reason}

  @doc category: :temporary_failure
  @spec proxy_error(reason :: String.t() | nil) :: t
  def proxy_error(reason \\ nil) when is_nil(reason) or is_binary(reason),
    do: %__MODULE__{code: 43, meta: reason}

  @doc category: :temporary_failure
  @spec slow_down(message :: pos_integer() | String.t() | nil) :: t
  def slow_down(message \\ nil)

  def slow_down(wait_time) when is_integer(wait_time) and wait_time > 0,
    do: slow_down("Too many requests. Wait #{wait_time} seconds.")

  def slow_down(message) when is_nil(message) or is_binary(message),
    do: %__MODULE__{code: 44, meta: message}

  # PERMANENT FAILURE

  @doc category: :permanent_failure
  @spec permanent_failure(desc :: String.t() | nil) :: t
  def permanent_failure(desc \\ nil) when is_nil(desc) or is_binary(desc),
    do: %__MODULE__{code: 50, meta: desc}

  @doc category: :permanent_failure
  @spec not_found(desc :: String.t() | nil) :: t
  def not_found(desc \\ nil) when is_nil(desc) or is_binary(desc),
    do: %__MODULE__{code: 51, meta: desc}

  @doc category: :permanent_failure
  @spec gone(desc :: String.t() | nil) :: t
  def gone(desc \\ nil) when is_nil(desc) or is_binary(desc),
    do: %__MODULE__{code: 52, meta: desc}

  @doc category: :permanent_failure
  @spec proxy_request_refused(desc :: String.t() | nil) :: t
  def proxy_request_refused(desc \\ nil) when is_nil(desc) or is_binary(desc),
    do: %__MODULE__{code: 53, meta: desc}

  @doc category: :permanent_failure
  @spec bad_request(desc :: String.t() | nil) :: t
  def bad_request(desc \\ nil) when is_nil(desc) or is_binary(desc),
    do: %__MODULE__{code: 59, meta: desc}

  # CLIENT CERTIFICATE

  @doc category: :certificate
  @spec client_certificate_required(prompt :: String.t() | nil) :: t
  def client_certificate_required(prompt \\ nil) when is_nil(prompt) or is_binary(prompt),
    do: %__MODULE__{code: 60, meta: prompt}

  @doc category: :certificate
  @spec certificate_not_authorised(prompt :: String.t() | nil) :: t
  def certificate_not_authorised(prompt \\ nil) when is_nil(prompt) or is_binary(prompt),
    do: %__MODULE__{code: 61, meta: prompt}

  @doc category: :certificate
  @spec certificate_not_valid(prompt :: String.t() | nil) :: t
  def certificate_not_valid(prompt \\ nil) when is_nil(prompt) or is_binary(prompt),
    do: %__MODULE__{code: 62, meta: prompt}
end
