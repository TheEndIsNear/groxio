defmodule LifeWeb.GameOfLifeTest do
  use ExUnit.Case, async: true

  alias LifeWeb.GameOfLife

  describe "random_grid/2" do
    test "creates cells within bounds" do
      grid = GameOfLife.random_grid(10, 15)

      Enum.each(grid, fn {row, col} ->
        assert row >= 0 and row < 10
        assert col >= 0 and col < 15
      end)
    end

    test "returns a MapSet" do
      grid = GameOfLife.random_grid(5, 5)
      assert %MapSet{} = grid
    end

    test "produces non-empty grids for reasonable sizes" do
      # With 30% chance per cell, a 20x20 grid should almost always have cells
      grid = GameOfLife.random_grid(20, 20)
      assert MapSet.size(grid) > 0
    end
  end

  describe "empty_grid/0" do
    test "returns an empty MapSet" do
      assert GameOfLife.empty_grid() == MapSet.new()
    end
  end

  describe "evolve/3" do
    test "block still life remains unchanged" do
      block = MapSet.new([{1, 1}, {1, 2}, {2, 1}, {2, 2}])
      assert GameOfLife.evolve(block, 20, 20) == block
    end

    test "blinker oscillates" do
      horizontal = MapSet.new([{5, 4}, {5, 5}, {5, 6}])
      vertical = MapSet.new([{4, 5}, {5, 5}, {6, 5}])

      assert GameOfLife.evolve(horizontal, 20, 20) == vertical
      assert GameOfLife.evolve(vertical, 20, 20) == horizontal
    end

    test "wraps around edges (toroidal)" do
      horizontal = MapSet.new([{5, 19}, {5, 0}, {5, 1}])
      vertical = MapSet.new([{4, 0}, {5, 0}, {6, 0}])

      assert GameOfLife.evolve(horizontal, 20, 20) == vertical
    end

    test "single cell dies (underpopulation)" do
      single = MapSet.new([{5, 5}])
      assert GameOfLife.evolve(single, 10, 10) == MapSet.new()
    end

    test "dead cell with exactly 3 neighbors comes alive" do
      # Three cells around {1,1} — it should come alive
      grid = MapSet.new([{0, 0}, {0, 1}, {0, 2}])
      evolved = GameOfLife.evolve(grid, 10, 10)
      assert MapSet.member?(evolved, {1, 1})
    end
  end

  describe "toggle_cell/3" do
    test "adds a dead cell" do
      grid = MapSet.new()
      result = GameOfLife.toggle_cell(grid, 3, 4)
      assert MapSet.member?(result, {3, 4})
    end

    test "removes an alive cell" do
      grid = MapSet.new([{3, 4}])
      result = GameOfLife.toggle_cell(grid, 3, 4)
      refute MapSet.member?(result, {3, 4})
    end
  end

  describe "alive_count/1" do
    test "returns the number of alive cells" do
      grid = MapSet.new([{0, 0}, {1, 1}, {2, 2}])
      assert GameOfLife.alive_count(grid) == 3
    end

    test "returns 0 for empty grid" do
      assert GameOfLife.alive_count(MapSet.new()) == 0
    end
  end

  describe "alive_cells_list/1" do
    test "returns sorted list of [row, col] pairs" do
      grid = MapSet.new([{2, 3}, {0, 1}, {1, 2}])
      assert GameOfLife.alive_cells_list(grid) == [[0, 1], [1, 2], [2, 3]]
    end

    test "returns empty list for empty grid" do
      assert GameOfLife.alive_cells_list(MapSet.new()) == []
    end
  end
end
