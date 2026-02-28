defmodule LifeWeb.GameOfLife.Server do
  @moduledoc """
  A GenServer that manages a Game of Life simulation instance.

  Each server holds the grid state and evolves it on a configurable timer.
  State changes are broadcast via `Phoenix.PubSub` so LiveView processes
  can subscribe and receive updates. Telemetry events are emitted on each
  tick for observability via LiveDashboard.
  """

  use GenServer

  alias LifeWeb.GameOfLife

  @default_rows 30
  @default_cols 30
  @default_tick_ms 200

  @type state :: %{
          grid: GameOfLife.grid(),
          rows: pos_integer(),
          cols: pos_integer(),
          generation: non_neg_integer(),
          tick_ms: pos_integer(),
          running: boolean(),
          topic: String.t(),
          timer_ref: reference() | nil
        }

  # --- Client API ---

  @doc """
  Starts a Game of Life server.

  ## Options

    * `:rows` - number of rows (default: #{@default_rows})
    * `:cols` - number of columns (default: #{@default_cols})
    * `:tick_ms` - milliseconds between generations (default: #{@default_tick_ms})
    * `:topic` - PubSub topic for broadcasting updates (required)
    * `:name` - GenServer name (optional)
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Returns the current state snapshot."
  def get_state(server), do: GenServer.call(server, :get_state)

  @doc "Toggles a cell at the given row and column."
  def toggle_cell(server, row, col), do: GenServer.cast(server, {:toggle_cell, row, col})

  @doc "Sets the simulation speed in milliseconds."
  def set_speed(server, tick_ms), do: GenServer.cast(server, {:set_speed, tick_ms})

  @doc "Resizes the grid. This resets the simulation with a new random grid."
  def resize(server, rows, cols), do: GenServer.cast(server, {:resize, rows, cols})

  @doc "Starts the simulation."
  def start(server), do: GenServer.cast(server, :start)

  @doc "Stops (pauses) the simulation."
  def stop(server), do: GenServer.cast(server, :stop)

  @doc "Advances the simulation by one generation (while paused)."
  def step(server), do: GenServer.cast(server, :step)

  @doc "Randomizes the grid."
  def randomize(server), do: GenServer.cast(server, :randomize)

  @doc "Clears the grid."
  def clear(server), do: GenServer.cast(server, :clear)

  # --- Callbacks ---

  @impl true
  def init(opts) do
    rows = Keyword.get(opts, :rows, @default_rows)
    cols = Keyword.get(opts, :cols, @default_cols)
    tick_ms = Keyword.get(opts, :tick_ms, @default_tick_ms)
    topic = Keyword.fetch!(opts, :topic)

    state = %{
      grid: GameOfLife.random_grid(rows, cols),
      rows: rows,
      cols: cols,
      generation: 0,
      tick_ms: tick_ms,
      running: false,
      topic: topic,
      timer_ref: nil
    }

    broadcast(state)
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, snapshot(state), state}
  end

  @impl true
  def handle_cast({:toggle_cell, row, col}, state) do
    new_grid = GameOfLife.toggle_cell(state.grid, row, col)
    state = %{state | grid: new_grid}
    broadcast(state)
    {:noreply, state}
  end

  def handle_cast({:set_speed, tick_ms}, state) do
    tick_ms = clamp(tick_ms, 50, 2000)
    state = cancel_timer(state)
    state = %{state | tick_ms: tick_ms}

    state =
      if state.running do
        schedule_tick(state)
      else
        state
      end

    broadcast(state)
    {:noreply, state}
  end

  def handle_cast({:resize, rows, cols}, state) do
    rows = clamp(rows, 5, 100)
    cols = clamp(cols, 5, 100)
    state = cancel_timer(state)

    state = %{
      state
      | grid: GameOfLife.random_grid(rows, cols),
        rows: rows,
        cols: cols,
        generation: 0,
        running: false
    }

    broadcast(state)
    {:noreply, state}
  end

  def handle_cast(:start, %{running: true} = state), do: {:noreply, state}

  def handle_cast(:start, state) do
    state = %{state | running: true}
    state = schedule_tick(state)
    broadcast(state)
    {:noreply, state}
  end

  def handle_cast(:stop, state) do
    state = cancel_timer(state)
    state = %{state | running: false}
    broadcast(state)
    {:noreply, state}
  end

  def handle_cast(:step, %{running: true} = state), do: {:noreply, state}

  def handle_cast(:step, state) do
    state = do_evolve(state)
    broadcast(state)
    {:noreply, state}
  end

  def handle_cast(:randomize, state) do
    state = cancel_timer(state)

    state = %{
      state
      | grid: GameOfLife.random_grid(state.rows, state.cols),
        generation: 0,
        running: false
    }

    broadcast(state)
    {:noreply, state}
  end

  def handle_cast(:clear, state) do
    state = cancel_timer(state)

    state = %{
      state
      | grid: GameOfLife.empty_grid(),
        generation: 0,
        running: false
    }

    broadcast(state)
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, %{running: true} = state) do
    state = do_evolve(state)
    state = schedule_tick(state)
    broadcast(state)
    {:noreply, state}
  end

  def handle_info(:tick, state), do: {:noreply, state}

  # --- Private helpers ---

  defp do_evolve(state) do
    {duration_us, new_grid} =
      :timer.tc(fn -> GameOfLife.evolve(state.grid, state.rows, state.cols) end)

    new_gen = state.generation + 1
    alive = GameOfLife.alive_count(new_grid)

    :telemetry.execute(
      [:game_of_life, :tick],
      %{duration: duration_us, alive_cells: alive},
      %{generation: new_gen, rows: state.rows, cols: state.cols}
    )

    %{state | grid: new_grid, generation: new_gen}
  end

  defp schedule_tick(state) do
    ref = Process.send_after(self(), :tick, state.tick_ms)
    %{state | timer_ref: ref}
  end

  defp cancel_timer(%{timer_ref: nil} = state), do: state

  defp cancel_timer(%{timer_ref: ref} = state) do
    Process.cancel_timer(ref)
    %{state | timer_ref: nil}
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(LifeWeb.PubSub, state.topic, {:game_update, snapshot(state)})
  end

  defp snapshot(state) do
    %{
      rows: state.rows,
      cols: state.cols,
      generation: state.generation,
      tick_ms: state.tick_ms,
      running: state.running,
      alive_cells: GameOfLife.alive_cells_list(state.grid),
      alive_count: GameOfLife.alive_count(state.grid)
    }
  end

  defp clamp(value, min, max), do: value |> max(min) |> min(max)
end
