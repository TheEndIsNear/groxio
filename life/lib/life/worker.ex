defmodule Life.Worker do
  use GenServer

  @moduledoc """
  A GenServer worker for managing the state of conway's game of life making use of the functional core in Life.Core. Also send tick messagges ever second to evolved the game state.
  """

  def start_link({height, width}) do
    GenServer.start_link(__MODULE__, {height, width}, name: __MODULE__)
  end

  @impl true
  def init({height, width}) do
    initial_state = Life.Core.new(height, width)
    schedule_tick()
    {:ok, initial_state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = Life.Core.evolve(state)
    IO.puts(Life.Core.to_string(new_state))
    schedule_tick()
    {:noreply, new_state}
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, 1000)
end
