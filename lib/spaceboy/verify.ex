defmodule Spaceboy.Verify do
  @moduledoc false

  def cert(_client_cert, _ev, _init) do
    {:valid, :unknown_user}
  end
end
