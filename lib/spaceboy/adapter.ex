defmodule Spaceboy.Adapter do
  @moduledoc false

  @callback child_spec(opts :: Keyword.t()) :: map()
  @callback send(ref :: any(), header :: String.t(), body :: String.t() | nil) :: :ok
  @callback send_file(ref :: any(), header :: String.t(), file :: Path.t()) :: :ok
  @callback disconnect(ref :: any()) :: :ok
end
