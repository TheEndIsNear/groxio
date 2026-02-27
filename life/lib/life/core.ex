defmodule Life.Core do
  @moduledoc """
  The functional core for Conway's Game of Life.
  """

  defstruct height: 0, width: 0, cells: %{}

  @type t :: %__MODULE__{height: non_neg_integer(), width: non_neg_integer(), cells: map()}

  @doc """
  Creates a new Life.Core struct with the given height and width.
  Also initializes a map of cells to a group of cells randomly set to alive or dead.
  """
  def new(height, width) do
    cells =
      for x <- 0..(width - 1), y <- 0..(height - 1), into: %{} do
        {{x, y}, :rand.uniform() > 0.5}
      end

    %__MODULE__{height: height, width: width, cells: cells}
  end

  @doc """
  Converts the Life.Core struct to a string representation.
  Each cell is represented by a character, for example, "O" for alive and "." for dead. It has new lines between rows.
  """
  def to_string(%__MODULE__{height: height, width: width, cells: cells}) do
    for x <- 0..(height - 1), into: "" do
      for y <- 0..(width - 1), into: "" do
        if Map.get(cells, {x, y}, false) do
          "0"
        else
          "."
        end
      end <> "\n"
    end
  end

  def evolve(%__MODULE__{height: height, width: width, cells: cells} = state) do
    new_cells =
      for x <- 0..(height - 1), y <- 0..(width - 1), into: %{} do
        cell = {x, y}
        alive_neighbors = count_alive_neighbors(cells, cell)
        alive = Map.get(cells, cell, false)

        if alive do
          {cell, alive_neighbors in [2, 3]}
        else
          {cell, alive_neighbors == 3}
        end
      end

    %__MODULE__{state | cells: new_cells}
  end

  defp count_alive_neighbors(cells, {x, y}) do
    for dx <- -1..1, dy <- -1..1, dx != 0 or dy != 0 do
      Map.get(cells, {x + dx, y + dy}, false)
    end
    |> Enum.count(& &1)
  end
end
