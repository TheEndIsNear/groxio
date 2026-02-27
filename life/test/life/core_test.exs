defmodule Life.CoreTest do
  use ExUnit.Case, async: true

  alias Life.Core

  test "new/2 creates a board with expected dimensions and cell count" do
    state = Core.new(3, 4)

    assert state.height == 3
    assert state.width == 4
    assert map_size(state.cells) == 12
  end

  test "to_string/1 renders alive and dead cells" do
    state = %Core{
      height: 2,
      width: 3,
      cells: %{
        {0, 0} => true,
        {0, 1} => false,
        {0, 2} => true,
        {1, 0} => false,
        {1, 1} => true,
        {1, 2} => false
      }
    }

    assert Core.to_string(state) == "0.0\n.0.\n"
  end

  test "evolve/1 keeps a 2x2 block stable" do
    state = %Core{
      height: 4,
      width: 4,
      cells:
        for(x <- 0..3, y <- 0..3, into: %{}, do: {{x, y}, false})
        |> Map.merge(%{{1, 1} => true, {1, 2} => true, {2, 1} => true, {2, 2} => true})
    }

    evolved = Core.evolve(state)

    assert evolved.cells[{1, 1}]
    assert evolved.cells[{1, 2}]
    assert evolved.cells[{2, 1}]
    assert evolved.cells[{2, 2}]
  end

  test "evolve/1 oscillates a blinker" do
    state = %Core{
      height: 5,
      width: 5,
      cells:
        for(x <- 0..4, y <- 0..4, into: %{}, do: {{x, y}, false})
        |> Map.merge(%{{2, 1} => true, {2, 2} => true, {2, 3} => true})
    }

    evolved = Core.evolve(state)

    assert evolved.cells[{1, 2}]
    assert evolved.cells[{2, 2}]
    assert evolved.cells[{3, 2}]

    refute evolved.cells[{2, 1}]
    refute evolved.cells[{2, 3}]
  end

  test "evolve/1 applies underpopulation and reproduction" do
    state = %Core{
      height: 3,
      width: 3,
      cells: %{
        {0, 0} => false,
        {0, 1} => true,
        {0, 2} => false,
        {1, 0} => false,
        {1, 1} => true,
        {1, 2} => false,
        {2, 0} => false,
        {2, 1} => false,
        {2, 2} => true
      }
    }

    evolved = Core.evolve(state)

    refute evolved.cells[{2, 2}]
    assert evolved.cells[{1, 2}]
  end
end
