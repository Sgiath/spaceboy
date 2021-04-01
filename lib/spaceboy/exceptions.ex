defmodule Spaceboy.OutOfSpecError do
  @moduledoc ~S"""
  Raised when atempted to do action which is not supported by Gemini specs
  """

  defexception [:message]
end
