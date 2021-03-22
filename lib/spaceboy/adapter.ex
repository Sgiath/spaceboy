defmodule Spaceboy.Adapter do
  @moduledoc false

  @callback child_spec(opts :: Keyword.t()) :: map()
  @callback send(pid(), String.t(), String.t() | nil) :: :ok
  @callback send_file(pid(), String.t(), Path.t()) :: :ok
end
