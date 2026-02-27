defmodule Life.Worker.DefaultBoundary do
  @behaviour Life.Worker.Boundary

  @impl true
  def new(height, width), do: Life.Core.new(height, width)

  @impl true
  def evolve(state), do: Life.Core.evolve(state)

  @impl true
  def render(state), do: Life.Core.to_string(state)

  @impl true
  def publish(output), do: IO.puts(output)

  @impl true
  def schedule_tick(pid, tick_ms), do: Process.send_after(pid, :tick, tick_ms)
end
