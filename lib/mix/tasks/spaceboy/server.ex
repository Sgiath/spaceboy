defmodule Mix.Tasks.Spaceboy.Server do
  @shortdoc "Starts the Gemini server"

  @moduledoc """
  Starts the configured Gemini server

  ## Command line options

  This task accepts the same command-line arguments as `run`. For additional
  information, refer to the documentation for `Mix.Tasks.Run`.

  For example, to run `spaceboy.server` without recompiling:

      mix phx.server --no-compile

  The `--no-halt` flag is automatically added.
  """

  use Mix.Task

  alias Mix.Tasks.Run

  @impl Mix.Task
  def run(args) do
    Run.run(["--no-halt" | args])
  end
end
