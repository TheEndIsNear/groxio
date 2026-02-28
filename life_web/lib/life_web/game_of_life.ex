defmodule LifeWeb.GameOfLife do
  @moduledoc """
  Conway's Game of Life core logic.

  The grid is represented as a `MapSet` of `{row, col}` tuples
  indicating which cells are alive. This is a pure-functional module
  with no side effects — all state management is handled by the server.
  """

  @type cell :: {non_neg_integer(), non_neg_integer()}
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
  Returns an empty grid.
  """
  @spec empty_grid() :: grid()
  def empty_grid, do: MapSet.new()

  @doc """
  Evolves the grid by one generation according to Conway's rules
  on a toroidal (wrapping) grid of the given dimensions:

  1. Any live cell with 2 or 3 neighbours survives.
  2. Any dead cell with exactly 3 neighbours becomes alive.
  3. All other live cells die, and all other dead cells stay dead.
  """
  @spec evolve(grid(), pos_integer(), pos_integer()) :: grid()
  def evolve(grid, rows, cols) do
    neighbour_counts =
      grid
      |> Enum.flat_map(&neighbours(&1, rows, cols))
      |> Enum.frequencies()

    for {cell, count} <- neighbour_counts,
        survives?(cell, count, grid),
        into: MapSet.new() do
      cell
    end
  end

  @doc """
  Toggles a cell between alive and dead.
  """
  @spec toggle_cell(grid(), non_neg_integer(), non_neg_integer()) :: grid()
  def toggle_cell(grid, row, col) do
    cell = {row, col}

    if MapSet.member?(grid, cell) do
      MapSet.delete(grid, cell)
    else
      MapSet.put(grid, cell)
    end
  end

  @doc """
  Returns the number of alive cells in the grid.
  """
  @spec alive_count(grid()) :: non_neg_integer()
  def alive_count(grid), do: MapSet.size(grid)

  @doc """
  Returns the list of alive cells as `[row, col]` pairs,
  suitable for sending to a JavaScript client.
  """
  @spec alive_cells_list(grid()) :: list([non_neg_integer()])
  def alive_cells_list(grid) do
    grid
    |> Enum.map(fn {row, col} -> [row, col] end)
    |> Enum.sort()
  end

  # --- Private helpers ---

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
end
