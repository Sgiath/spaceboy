defmodule Mix.Tasks.Spaceboy.Server do
  use Mix.Task

  def run(args) do
    Mix.Tasks.Run.run(["--no-halt" | args])
  end
end
