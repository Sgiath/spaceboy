defmodule Spaceboy.OutOfSpecError do
  @moduledoc ~S"""
  Raised when attempted to do action which is not supported by Gemini specs
  """

  defexception [:message]
end
