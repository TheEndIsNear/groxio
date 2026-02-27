defmodule Life.Worker do
  use GenServer

  @moduledoc """
  A GenServer worker for managing the state of conway's game of life making use of the functional core in Life.Core. Also send tick messagges ever second to evolved the game state.
  """

  def start_link({height, width}) do
    start_link(height: height, width: width, name: __MODULE__)
  end

  def start_link(opts) when is_list(opts) do
    height = Keyword.fetch!(opts, :height)
    width = Keyword.fetch!(opts, :width)
    name = Keyword.get(opts, :name, __MODULE__)
    boundary = Keyword.get(opts, :boundary, Life.Worker.DefaultBoundary)
    tick_ms = Keyword.get(opts, :tick_ms, 1000)

    GenServer.start_link(
      __MODULE__,
      %{height: height, width: width, boundary: boundary, tick_ms: tick_ms},
      name: name
    )
  end

  @impl true
  def init(%{height: height, width: width, boundary: boundary, tick_ms: tick_ms}) do
    core_state = boundary.new(height, width)
    boundary.schedule_tick(self(), tick_ms)
    {:ok, %{core_state: core_state, boundary: boundary, tick_ms: tick_ms}}
  end

  @impl true
  def handle_info(
        :tick,
        %{core_state: state, boundary: boundary, tick_ms: tick_ms} = worker_state
      ) do
    new_state = boundary.evolve(state)
    new_state |> boundary.render() |> boundary.publish()
    boundary.schedule_tick(self(), tick_ms)
    {:noreply, %{worker_state | core_state: new_state}}
  end
end
