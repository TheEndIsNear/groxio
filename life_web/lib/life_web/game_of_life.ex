defmodule LifeWeb.GameOfLife do
  @moduledoc """
  Conway's Game of Life core logic.

  The grid is represented as a `MapSet` of `{row, col}` tuples
  indicating which cells are alive. This is a pure-functional module
  with no side effects — all state management is handled by the server.
  """

  @type cell :: {non_neg_integer(), non_neg_integer()}
  @type grid :: MapSet.t()

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
  @dialyzer {:nowarn_function, empty_grid: 0}
  @spec empty_grid() :: grid()
  def empty_grid do
    MapSet.new()
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

  # --- Famous Patterns ---

  @doc """
  Returns a list of all available pattern definitions, grouped by category.

  Each pattern is a map with:
    * `:name` - human-readable name
    * `:key` - atom identifier
    * `:category` - one of :still_life, :oscillator, :spaceship, :generator
    * `:cells` - list of `{row, col}` tuples (origin-relative)
  """
  @spec patterns() :: [map()]
  def patterns do
    [
      # Still lifes
      %{
        name: "Block",
        key: :block,
        category: :still_life,
        cells: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
      },
      %{
        name: "Beehive",
        key: :beehive,
        category: :still_life,
        cells: [{0, 1}, {0, 2}, {1, 0}, {1, 3}, {2, 1}, {2, 2}]
      },
      %{
        name: "Loaf",
        key: :loaf,
        category: :still_life,
        cells: [{0, 1}, {0, 2}, {1, 0}, {1, 3}, {2, 1}, {2, 3}, {3, 2}]
      },
      # Oscillators
      %{
        name: "Blinker",
        key: :blinker,
        category: :oscillator,
        cells: [{0, 0}, {0, 1}, {0, 2}]
      },
      %{
        name: "Toad",
        key: :toad,
        category: :oscillator,
        cells: [{0, 1}, {0, 2}, {0, 3}, {1, 0}, {1, 1}, {1, 2}]
      },
      %{
        name: "Beacon",
        key: :beacon,
        category: :oscillator,
        cells: [{0, 0}, {0, 1}, {1, 0}, {2, 3}, {3, 2}, {3, 3}]
      },
      %{
        name: "Pulsar",
        key: :pulsar,
        category: :oscillator,
        cells: pulsar_cells()
      },
      # Spaceships
      %{
        name: "Glider",
        key: :glider,
        category: :spaceship,
        cells: [{0, 1}, {1, 2}, {2, 0}, {2, 1}, {2, 2}]
      },
      %{
        name: "LWSS",
        key: :lwss,
        category: :spaceship,
        cells: [
          {0, 1},
          {0, 4},
          {1, 0},
          {2, 0},
          {2, 4},
          {3, 0},
          {3, 1},
          {3, 2},
          {3, 3}
        ]
      },
      # Generators
      %{
        name: "Gosper Glider Gun",
        key: :gosper_glider_gun,
        category: :generator,
        cells: gosper_glider_gun_cells()
      }
    ]
  end

  @doc """
  Looks up a pattern by its key atom.
  Returns `{:ok, pattern}` or `:error`.
  """
  @spec get_pattern(atom()) :: {:ok, map()} | :error
  def get_pattern(key) do
    case Enum.find(patterns(), fn p -> p.key == key end) do
      nil -> :error
      pattern -> {:ok, pattern}
    end
  end

  @doc """
  Places a pattern centered on a grid of the given dimensions.
  Returns a new grid (MapSet) containing only the pattern cells.
  Cells that fall outside the grid boundaries are wrapped toroidally.
  """
  @spec place_pattern(atom(), pos_integer(), pos_integer()) :: {:ok, grid()} | :error
  def place_pattern(key, rows, cols) do
    case get_pattern(key) do
      {:ok, pattern} ->
        {max_r, max_c} = pattern_dimensions(pattern.cells)
        offset_r = div(rows - max_r - 1, 2)
        offset_c = div(cols - max_c - 1, 2)

        grid =
          for {r, c} <- pattern.cells, into: MapSet.new() do
            {Integer.mod(r + offset_r, rows), Integer.mod(c + offset_c, cols)}
          end

        {:ok, grid}

      :error ->
        :error
    end
  end

  defp pattern_dimensions(cells) do
    {max_r, _} = Enum.max_by(cells, fn {r, _c} -> r end)
    {_, max_c} = Enum.max_by(cells, fn {_r, c} -> c end)
    {max_r, max_c}
  end

  defp pulsar_cells do
    # Pulsar is symmetric across both axes — define one quadrant and reflect
    quadrant = [
      {1, 2},
      {1, 3},
      {1, 4},
      {2, 1},
      {3, 1},
      {4, 1},
      {2, 6},
      {3, 6},
      {4, 6},
      {6, 2},
      {6, 3},
      {6, 4}
    ]

    quadrant
    |> Enum.flat_map(fn {r, c} ->
      [{r, c}, {r, 12 - c}, {12 - r, c}, {12 - r, 12 - c}]
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp gosper_glider_gun_cells do
    [
      # Left square
      {4, 0},
      {4, 1},
      {5, 0},
      {5, 1},
      # Left structure
      {4, 10},
      {5, 10},
      {6, 10},
      {3, 11},
      {7, 11},
      {2, 12},
      {8, 12},
      {2, 13},
      {8, 13},
      {5, 14},
      {3, 15},
      {7, 15},
      {4, 16},
      {5, 16},
      {6, 16},
      {5, 17},
      # Right structure
      {2, 20},
      {3, 20},
      {4, 20},
      {2, 21},
      {3, 21},
      {4, 21},
      {1, 22},
      {5, 22},
      {0, 24},
      {1, 24},
      {5, 24},
      {6, 24},
      # Right square
      {2, 34},
      {3, 34},
      {2, 35},
      {3, 35}
    ]
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
