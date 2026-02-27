defmodule GameOfLife.Server do
  @moduledoc """
  A GenServer that holds the Game of Life state and evolves it
  on a one-second timer, printing each generation to the console.
  """

  use GenServer

  @rows 20
  @cols 20
  @tick_interval 1_000
  @blank_lines 30

  # --- Client API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # --- Callbacks ---

  @impl true
  def init(_opts) do
    grid = GameOfLife.random_grid(@rows, @cols)
    print_grid(grid, _generation = 0)
    schedule_tick()
    {:ok, %{grid: grid, generation: 0}}
  end

  @impl true
  def handle_info(:tick, %{grid: grid, generation: gen} = _state) do
    new_grid = GameOfLife.evolve(grid, @rows, @cols)
    new_gen = gen + 1
    print_grid(new_grid, new_gen)
    schedule_tick()
    {:noreply, %{grid: new_grid, generation: new_gen}}
  end

  # --- Helpers ---

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp print_grid(grid, generation) do
    blanks = String.duplicate("\n", @blank_lines)
    rendered = GameOfLife.render(grid, @rows, @cols)

    IO.write(blanks)
    IO.write("=== Generation #{generation} ===\n")
    IO.write(rendered)
  end
end
