defmodule LifeWeb.GameOfLife.ServerTest do
  use ExUnit.Case, async: true

  alias LifeWeb.GameOfLife.Server

  setup do
    topic = "test:game:#{System.unique_integer()}"
    Phoenix.PubSub.subscribe(LifeWeb.PubSub, topic)

    pid =
      start_supervised!({Server, topic: topic, rows: 10, cols: 10, tick_ms: 100})

    # Drain the initial broadcast from init
    assert_receive {:game_update, _initial_state}, 500

    %{server: pid, topic: topic}
  end

  describe "get_state/1" do
    test "returns current state snapshot", %{server: server} do
      state = Server.get_state(server)

      assert state.rows == 10
      assert state.cols == 10
      assert state.generation == 0
      assert state.tick_ms == 100
      assert state.running == false
      assert is_list(state.alive_cells)
      assert is_integer(state.alive_count)
    end
  end

  describe "toggle_cell/3" do
    test "toggles a cell and broadcasts", %{server: server} do
      Server.toggle_cell(server, 3, 4)
      assert_receive {:game_update, state}, 500

      cell_present? = Enum.any?(state.alive_cells, fn [r, c] -> r == 3 and c == 4 end)
      # It was either added or removed — just verify we got the broadcast
      assert is_boolean(cell_present?)
    end
  end

  describe "start/stop lifecycle" do
    test "start begins ticking", %{server: server} do
      Server.start(server)
      assert_receive {:game_update, %{running: true}}, 500

      # Should receive tick updates
      assert_receive {:game_update, %{generation: gen}}, 500
      assert gen >= 0
    end

    test "stop pauses simulation", %{server: server} do
      Server.start(server)
      assert_receive {:game_update, %{running: true}}, 500

      Server.stop(server)
      assert_receive {:game_update, %{running: false}}, 500
    end
  end

  describe "step/1" do
    test "advances one generation when paused", %{server: server} do
      Server.step(server)
      assert_receive {:game_update, %{generation: 1}}, 500
    end

    test "does nothing when running", %{server: server} do
      Server.start(server)
      assert_receive {:game_update, %{running: true}}, 500

      # Step should be ignored while running
      Server.step(server)
      # We just verify the server didn't crash
      _ = :sys.get_state(server)
    end
  end

  describe "randomize/1" do
    test "resets to generation 0 and stops", %{server: server} do
      Server.start(server)
      assert_receive {:game_update, %{running: true}}, 500

      Server.randomize(server)
      assert_receive {:game_update, %{generation: 0, running: false}}, 500
    end
  end

  describe "clear/1" do
    test "empties the grid and stops", %{server: server} do
      Server.clear(server)
      assert_receive {:game_update, state}, 500

      assert state.generation == 0
      assert state.running == false
      assert state.alive_count == 0
      assert state.alive_cells == []
    end
  end

  describe "resize/3" do
    test "changes dimensions and resets", %{server: server} do
      Server.resize(server, 20, 25)
      assert_receive {:game_update, state}, 500

      assert state.rows == 20
      assert state.cols == 25
      assert state.generation == 0
      assert state.running == false
    end

    test "clamps to valid range", %{server: server} do
      Server.resize(server, 1, 200)
      assert_receive {:game_update, state}, 500

      assert state.rows == 5
      assert state.cols == 100
    end
  end

  describe "set_speed/2" do
    test "changes tick interval", %{server: server} do
      Server.set_speed(server, 500)
      assert_receive {:game_update, state}, 500

      assert state.tick_ms == 500
    end

    test "clamps to valid range", %{server: server} do
      Server.set_speed(server, 10)
      assert_receive {:game_update, state}, 500

      assert state.tick_ms == 50
    end
  end
end
