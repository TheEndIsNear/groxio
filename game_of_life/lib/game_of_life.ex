defmodule GameOfLife do
  @moduledoc """
  Conway's Game of Life core logic.

  The grid is represented as a MapSet of `{row, col}` tuples
  indicating which cells are alive.
  """

  @type cell :: {integer(), integer()}
  @type grid :: MapSet.t(cell())

  @doc """
  Creates a random grid of the given dimensions.
  Each cell has roughly a 30% chance of being alive.
  """
  @spec random_grid(pos_integer(), pos_integer()) :: grid()
  def random_grid(rows, cols) do
    for row <- 0..(rows - 1),
        col <- 0..(cols - 1),
        :rand.uniform(100) <= 30,
        into: MapSet.new() do
      {row, col}
    end
  end

  @doc """
  Evolves the grid by one generation according to Conway's rules
  on a toroidal (wrapping) grid of the given dimensions:

  1. Any live cell with 2 or 3 neighbours survives.
  2. Any dead cell with exactly 3 neighbours becomes alive.
  3. All other live cells die, and all other dead cells stay dead.
  """
  @spec evolve(grid(), pos_integer(), pos_integer()) :: grid()
  def evolve(grid, rows, cols) do
    # Build a map of every cell that borders at least one alive cell,
    # with the count of alive neighbours it has.
    neighbour_counts =
      grid
      |> Enum.flat_map(&neighbours(&1, rows, cols))
      |> Enum.frequencies()

    # Apply the rules
    for {cell, count} <- neighbour_counts,
        survives?(cell, count, grid),
        into: MapSet.new() do
      cell
    end
  end

  defp survives?(cell, count, grid) do
    alive? = MapSet.member?(grid, cell)
    (alive? and count in [2, 3]) or (not alive? and count == 3)
  end

  defp neighbours({row, col}, rows, cols) do
    for dr <- -1..1,
        dc <- -1..1,
        {dr, dc} != {0, 0} do
      {Integer.mod(row + dr, rows), Integer.mod(col + dc, cols)}
    end
  end

  @doc """
  Renders the grid as a string for display.
  Alive cells are shown as `█`, dead cells as `·`.
  """
  @spec render(grid(), pos_integer(), pos_integer()) :: String.t()
  def render(grid, rows, cols) do
    for row <- 0..(rows - 1), into: "" do
      line =
        for col <- 0..(cols - 1), into: "" do
          if MapSet.member?(grid, {row, col}), do: "█ ", else: "· "
        end

      line <> "\n"
    end
  end
end
