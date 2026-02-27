defmodule GameOfLife.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GameOfLife.Server
    ]

    opts = [strategy: :one_for_one, name: GameOfLife.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
