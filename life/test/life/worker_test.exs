defmodule Life.WorkerTest do
  use ExUnit.Case, async: false

  alias Life.Core

  defmodule FakeBoundary do
    @behaviour Life.Worker.Boundary

    @impl true
    def new(height, width) do
      notify_test({:new_called, height, width})

      %Core{
        height: height,
        width: width,
        cells: for(x <- 0..(height - 1), y <- 0..(width - 1), into: %{}, do: {{x, y}, false})
      }
    end

    @impl true
    def evolve(%Core{} = state) do
      notify_test({:evolve_called, state})
      %Core{state | cells: Map.put(state.cells, {0, 0}, true)}
    end

    @impl true
    def render(state) do
      notify_test({:render_called, state})
      "rendered"
    end

    @impl true
    def publish(output) do
      notify_test({:publish_called, output})
      :ok
    end

    @impl true
    def schedule_tick(pid, tick_ms) do
      notify_test({:schedule_called, pid, tick_ms})
      make_ref()
    end

    defp notify_test(message) do
      case :persistent_term.get({__MODULE__, :test_pid}, nil) do
        nil -> :ok
        test_pid -> send(test_pid, message)
      end
    end
  end

  setup do
    :persistent_term.put({FakeBoundary, :test_pid}, self())

    on_exit(fn ->
      :persistent_term.erase({FakeBoundary, :test_pid})
    end)

    :ok
  end

  test "init builds core state and schedules first tick" do
    pid =
      start_supervised!({Life.Worker, [height: 3, width: 4, name: nil, boundary: FakeBoundary]})

    assert_received {:new_called, 3, 4}
    assert_received {:schedule_called, ^pid, 1000}

    state = :sys.get_state(pid)
    assert state.core_state.height == 3
    assert state.core_state.width == 4
  end

  test "tick goes through evolve, render, publish and re-schedules" do
    pid =
      start_supervised!(
        {Life.Worker, [height: 2, width: 2, name: nil, boundary: FakeBoundary, tick_ms: 10]}
      )

    assert_receive {:new_called, 2, 2}
    assert_receive {:schedule_called, ^pid, 10}

    send(pid, :tick)

    assert_receive {:evolve_called, %Core{height: 2, width: 2}}
    assert_receive {:render_called, %Core{cells: cells}}
    assert cells[{0, 0}]
    assert_receive {:publish_called, "rendered"}
    assert_receive {:schedule_called, ^pid, 10}
  end
end
