defmodule Example.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [Example.Server]

    Supervisor.start_link(children, strategy: :one_for_one, name: Example.Supervisor)
  end
end
