defmodule Life.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Life.Worker.start_link(arg)
      # Start the Life.Worker with a 5x5 grid
      {Life.Worker, {5, 5}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Life.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
