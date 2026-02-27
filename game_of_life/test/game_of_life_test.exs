defmodule GameOfLifeTest do
  use ExUnit.Case

  test "random_grid creates cells within bounds" do
    grid = GameOfLife.random_grid(20, 20)

    Enum.each(grid, fn {row, col} ->
      assert row >= 0 and row < 20
      assert col >= 0 and col < 20
    end)
  end

  test "evolve applies Conway's rules - block still life" do
    # A 2x2 block is a still life — it should not change
    block = MapSet.new([{1, 1}, {1, 2}, {2, 1}, {2, 2}])
    assert GameOfLife.evolve(block, 20, 20) == block
  end

  test "evolve applies Conway's rules - blinker oscillator" do
    # Horizontal blinker should become vertical (away from edges to avoid wrap effects)
    horizontal = MapSet.new([{5, 4}, {5, 5}, {5, 6}])
    vertical = MapSet.new([{4, 5}, {5, 5}, {6, 5}])

    assert GameOfLife.evolve(horizontal, 20, 20) == vertical
    assert GameOfLife.evolve(vertical, 20, 20) == horizontal
  end

  test "evolve wraps around edges (toroidal)" do
    # A horizontal blinker straddling the right edge should wrap
    # Cells at col 19, 0, 1 on row 5 in a 20-col grid
    horizontal = MapSet.new([{5, 19}, {5, 0}, {5, 1}])
    vertical = MapSet.new([{4, 0}, {5, 0}, {6, 0}])

    assert GameOfLife.evolve(horizontal, 20, 20) == vertical
  end

  test "render produces correct output" do
    grid = MapSet.new([{0, 0}, {1, 1}])
    output = GameOfLife.render(grid, 2, 2)
    assert output == "█ · \n· █ \n"
  end
end
